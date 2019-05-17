defmodule Caravan.Distribution.Monitor do
  @moduledoc false
  use GenServer
  require Logger

  def start_link(args) do
    name = args[:name]
    GenServer.start_link(__MODULE__, args, name: name)
  end

  @impl true
  def init(args) do
    child_spec = args[:process_spec]
    process_supervisor = args[:process_supervisor]
    base_name = args[:base_name]
    process_name = process_name(base_name, child_spec.name)
    name = args[:name]

    Process.flag(:trap_exit, true)

    # lock_id = {id, Node.self()}
    # scoped_name = :"#{base_name}.#{name}"

    pid = find_or_start_process(child_spec, process_name, process_supervisor)
    Process.monitor(pid)

    send(self(), :process_registry_check)

    {:ok,
     %{
       spec: child_spec,
       name: name,
       process_name: process_name,
       process_supervisor: process_supervisor,
       base_name: base_name
     }}
  end

  def find_or_start_process(
        %{id: id, supervisor_spec: spec},
        process_name,
        process_supervisor
      ) do
    lock_id = {id, Node.self()}

    :global.sync()

    :global.trans(lock_id, fn ->
      case :global.whereis_name(process_name) do
        :undefined ->
          {:ok, pid} = DynamicSupervisor.start_child(process_supervisor, spec)

          case :global.register_name(process_name, pid) do
            :yes ->
              pid

            :no ->
              Logger.warn("Process was started outside of :global.trans. Returning that process...")
              :ok = DynamicSupervisor.terminate_child(process_supervisor, pid)
              :global.whereis_name(process_name)
          end

        pid when is_pid(pid) ->
          pid
      end
    end)
  end

  ##
  # Checks that the process is registered in :global and starts it if not found. Basically a
  # failsafe in the event that a rebalance fails or something unexpected happens.
  def handle_info(:process_registry_check, state) do
    _ = Process.send_after(self(), :process_registry_check, 60_000)

    Logger.debug(fn -> "[#{state.name}] executing :process_registry_check" end)

    case :global.whereis_name(state.process_name) do
      :undefined ->
        Logger.debug(fn -> "[#{state.name}] not found in :global, starting..." end)
        pid = find_or_start_process(state.child_spec, state.process_name, state.process_supervisor)
        Process.monitor(pid)

      _ ->
        Logger.debug(fn -> "[#{state.name}] process is in :global, no action needed" end)
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    _ =
      Logger.debug(fn ->
        "[#{state.name}]: monitored process #{inspect(pid)} is down with reason: [#{reason}]"
      end)

    pid = find_or_start_process(state.spec, state.base_name, state.process_supervisor)
    Process.monitor(pid)

    {:noreply, state}
  end

  ##
  # Process names are scoped to the base name to prevent :global name conflicts
  defp process_name(base_name, process_name) do
    :"#{base_name}.#{process_name}"
  end
end
