defmodule Caravan.Registry.Monitor do
  @moduledoc """
  Starts and monitors a process, ensuring that it will be restarted in the event of cluster
  partitions.

  ## Is this safe?

  In general, you should start all processes under a supervision tree. However, we're sort of
  violating this by using a GenServer to start a process and handling specific exit reasons. I
  haven't found another way that isn't exceedingly complicated or even more "hacky" than what I'm doing
  here, but you _could_ run into unexpected behaviour as a result.
  """

  use GenServer

  require Logger

  defstruct [:name, :mfa, :pid, :opts, :callback, :test_pid]

  def get_child_pid(:undefined) do
    :undefined
  end

  def get_child_pid(name) do
    GenServer.call(name, :get_child_pid)
  end

  def start_link(args) do
    name = args[:name]
    mfa = args[:mfa]
    opts = Keyword.get(args, :opts, [])
    start_link(name, mfa, opts)
  end

  @doc false
  def start_link(name, {_, _, _} = mfa, opts) do
    state = %__MODULE__{name: name, mfa: mfa, opts: opts}
    GenServer.start_link(__MODULE__, state)
  end

  ## GenServer callbacks

  @doc false
  @impl GenServer
  def init(%__MODULE__{} = state) do
    Process.flag(:trap_exit, true)

    callback =
      if state.opts[:test_pid] != nil do
        fn arg ->
          send(state.opts[:test_pid], arg)
        end
      else
        fn _arg -> :ok end
      end

    Process.send_after(self(), :check_process_location, 10_000)

    case start_process(state.name, state.mfa, callback) do
      pid when is_pid(pid) ->
        {:ok, %{state | callback: callback, pid: pid}}

      other ->
        {:stop, {:child_proc_no_start, other}, %{state | callback: callback}}
    end
  end

  @impl GenServer
  def handle_call(:get_child_pid, _, %{pid: pid} = state) do
    {:reply, pid, state}
  end

  @doc false
  @impl GenServer
  def handle_call(request, _from, %__MODULE__{pid: pid} = state) when is_pid(pid) do
    reply = GenServer.call(pid, request)

    {:reply, reply, state}
  end

  @impl GenServer
  def handle_info(:check_process_location, state) do
    Process.send_after(self(), :check_process_location, 60_000)

    case Caravan.Registry.whereis_name(state.name) do
      pid when is_pid(pid) ->
        nodes = [Node.self() | Node.list()] |> Enum.sort()
        process_node = :erlang.node(pid)
        target_node = determine_node_to_run_on(state.name, nodes)

        if process_node != target_node do
          debug(fn -> "Process #{i(state.name)} should be moved to #{i(target_node)}" end)
          Process.exit(pid, {:shutdown, {:move_node, target_node}})
        end

      :undefined ->
        warn(":check_process_location not found #{i(state.name)}")
        send(self(), {:track_moved_process, 1})
        nil
    end

    state.callback.({:check_process_location, {Node.self(), state.name()}})

    {:noreply, state}
  end

  def handle_info({:track_moved_process, attempt}, %__MODULE__{} = state) when attempt > 1 do
    warn("Tracking moved process reached max attempts. Attempting to start process")
    pid = start_process(state.name, state.mfa, state.callback)
    {:noreply, %{state | pid: pid}}
  end

  @impl GenServer
  def handle_info({:track_moved_process, attempt}, %__MODULE__{} = state) do
    pid =
      case Caravan.Registry.whereis_name(state.name) do
        pid when is_pid(pid) ->
          debug(fn -> "Found moved process #{i(state.name)}. Linking..." end)
          Process.link(pid)
          state.callback.({:track_moved_process, {Node.self(), :found, state.name, pid}})
          pid

        :undefined ->
          warn(fn -> "Could not track process #{i(state.name)}. Attempt: #{attempt}" end)
          Process.send_after(self(), {:track_moved_process, attempt + 1}, 30_000)
          nil
      end

    {:noreply, %{state | pid: pid}}
  end

  @impl GenServer
  def handle_info({:EXIT, _, {:shutdown, {:move_node, target_node}}}, state) do
    debug(fn -> "Got message to move #{i(state.name)} to #{i(target_node)}" end)

    if target_node == Node.self() do
      pid = start_process(state.name, state.mfa, state.callback)
      state.callback.({:moving_node_exit, {Node.self(), target_node}})
      {:noreply, %{state | pid: pid}}
    else
      Process.send_after(self(), {:track_moved_process, 0}, 30_000)
      {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info({:EXIT, deadpid, {:shutdown, :global_name_conflict}}, state) do
    debug(fn ->
      "Got shutdown global name conflict #{i(state.name)} [#{i(deadpid)}], track new process"
    end)

    state.callback.({:caught_global_name_conflict, Node.self(), state.name})

    pid = start_process(state.name, state.mfa, state.callback)
    {:noreply, %{state | pid: pid}}
  end

  @impl GenServer
  def handle_info({:EXIT, old_pid, reason} = exit, state)
      when reason in [:noconnection, :noproc] do
    debug(fn -> "Got EXIT #{i(reason)} for  #{i(state.name)}[#{i(old_pid)}]. Restarting..." end)
    state.callback.({:caught_exit, exit})

    pid = start_process(state.name, state.mfa, state.callback)
    {:noreply, %{state | pid: pid}}
  end

  @impl GenServer
  def handle_info({:EXIT, old_pid, reason} = exit, state) do
    debug(fn -> "Got unhandled EXIT #{i(reason)} #{i(state.name)}  #{i(old_pid)}" end)
    state.callback.({:caught_exit, exit})

    {:stop, reason, state}
  end

  ## End GenServer callbacks

  defp start_process(name, {_, _, _} = mfa, callback) do
    case Caravan.Registry.ConflictHandler.start_link(name, mfa) do
      {:ok, pid} ->
        debug(fn ->
          "Started ConflictHandler #{inspect(name)} [#{inspect(pid)}] on #{Node.self()}"
        end)

        callback.({:started_process, {Node.self(), name, pid}})
        pid

      {:error, {:already_started, pid}} ->
        callback.({:already_started, {Node.self(), name, pid}})

        debug(fn ->
          "Linking existing ConflictHandler #{inspect(name)} [#{inspect(pid)}] on #{Node.self()}"
        end)

        Process.link(pid)
        pid
    end
  end

  defp determine_node_to_run_on(name, node_list) do
    count = length(node_list)

    index = XXHash.xxh32(name_to_hash(name)) |> rem(count)
    Enum.at(node_list, index)
  end

  defp name_to_hash(name) do
    name |> :erlang.term_to_binary() |> Base.encode16()
  end

  defp i(any), do: inspect(any)

  defdelegate debug(chardata_or_fun), to: Logger
  defdelegate warn(chardata_or_fun), to: Logger
end
