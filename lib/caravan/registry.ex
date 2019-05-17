defmodule Caravan.Registry do
  @moduledoc """
  A `Registry` like interface that is backed by Erlang's `:global` process registry. Also provides a
  `start_link/3` function to start a process with a `Caravan.Registry.Monitor` that will ensure the
  processes are restarted in the event of network partitions.
  """

  alias Caravan.Registry.Monitor
  ### :via callbacks

  @doc false
  def whereis_name({_registry, key}), do: whereis_name(key)

  def whereis_name(key) do
    :global.whereis_name(key)
  end

  @doc false
  def register_name(key, pid) when pid == self() do
    case register(key) do
      {:ok, _} -> :yes
      {:error, _} -> :no
      reply -> reply
    end
  end

  @doc false
  def send({_registry, key}, msg) do
    :global.send(key, msg)
  end

  def send(key, msg) do
    :global.send(key, msg)
  end

  @doc false
  def unregister_name({_registry, key}) do
    :global.unregister_name(key)
  end

  ## end :via callbacks

  @doc """
  Starts a process using a MFA tuple. The process will be started by a Registry.Monitor process that will
  ensure that the process stays running. Also, the Monitor will stop and restart processes on
  different nodes in order to achieve something closer to a uniform distribution.

  ### Important! ###
  You will need to explicitly set restart options when starting the process and cannot rely on the `child_spec/1`.
  This is because your Supervisor will actually be starting a `Caravan.Registry.Monitor` in the
  that will then start your actual process (via the MFA)
  """
  def start_link(name, {m,f,a} , opts \\ []) do
    Monitor.start_link(name, {m,f,a}, opts)
  end

  @doc """
  Register a process.
  """
  @spec register(name :: term) :: {:ok, pid} | {:error, :could_not_register}
  def register(name) do
    pid = self()
    case :global.register_name(name, pid) do
      :yes -> {:ok, pid}
      :no -> {:error, :could_not_register}
    end
  end

  @doc """
  Lookup a process
  """
  @spec lookup(name :: term) :: [{pid, nil}] | []
  def lookup(name) do
    case :global.whereis_name(name) do
      pid when is_pid(pid) -> [{pid, nil}]
      :undefined -> []
    end
  end

  @doc """
  Returns a :via tuple that can be used with GenServers or Supervisors to register or lookup via the
  mechanisms described here: https://hexdocs.pm/elixir/GenServer.html#module-name-registration
  """
  def via_tuple(name) do
    {:via, Caravan.Registry, name}
  end

  @doc """
  Unregister a name
  """
  @spec unregister(name :: term) :: :ok
  def unregister(name) do
    :global.unregister_name(name)
  end
end
