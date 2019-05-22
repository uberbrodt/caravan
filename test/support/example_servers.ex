defmodule Caravan.Test.Cluster do
  def start_cluster(count, test_pid) do
    nodes = LocalCluster.start_nodes("my-caravan", count)

    for node <- nodes do
      :pong = Node.ping(node)
      {:ok, _} = setup_node(node, test_pid)
    end

    setup_node(Node.self(), test_pid)

    nodes
  end

  def setup_node(node, test_pid) do
    rpc(node, Caravan.ExampleSupervisor, :start_link, [[test_pid: test_pid]])
  end

  def rpc(node, module, fun, args) do
    :rpc.block_call(node, module, fun, args)
  end
end

defmodule Caravan.ExampleSupervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(args) do
    children = [
      Supervisor.child_spec({Caravan.ExampleServer, [name: "permanent_example"] ++ args},
        id: "permanent_example",
        restart: :permanent
      ),
      Supervisor.child_spec({Caravan.ExampleServer, [name: "transient_example"] ++ args},
        id: "transient_example",
        restart: :transient
      )
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Caravan.ExampleServer do
  use GenServer
  require Logger

  def start_link(args) do
    Caravan.Registry.start_link(args[:name], {GenServer, :start_link, [__MODULE__, args, []]}, args)
  end

  def crash(name) do
    GenServer.cast(name, :crash_server)
  end

  def shutdown_normal(name) do
    GenServer.cast(name, :shutdown_normal)
  end

  def check(name) when is_pid(name) do
    GenServer.call(name, :status)
  end

  def check(name) do
    GenServer.call(Caravan.Registry.via_tuple(name), :status)
  end

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl GenServer
  def handle_call(:status, _from, state) do
    {:reply, {:ok, self()}, state}
  end

  @impl GenServer
  def handle_cast(:crash_server, state) do
    {:stop, :crashed, state}
  end

  @impl GenServer
  def handle_cast(:shutdown_normal, state) do
    {:stop, :normal, state}
  end
end
