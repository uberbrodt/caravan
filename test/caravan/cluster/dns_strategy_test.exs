defmodule Caravan.Cluster.DnsStrategyTest do
  use ExUnit.Case
  alias Cluster.Strategy.State

  defmodule TestClient do
    def get_nodes(name, _opts) when is_binary(name) do
      [{7000, "somenode.foo.example.net"}]
    end
  end

  @tag capture_log: true
  test "connect/1 gets correct node names" do
    config = %State{
      topology: :caravan,
      connect: {Caravan.Cluster.DnsStrategyTest, :connect_test, []},
      list_nodes: {:erlang, :nodes, [:connected]},
      config: [
        dns_client: Caravan.Cluster.DnsStrategyTest.TestClient,
        node_sname: "connectnodetest",
        query: "fooo"
      ]
    }

    {:ok, _} = start_supervised({Caravan.Cluster.DnsStrategy, [config]})
    :timer.sleep(100)
  end

  test "start_link/1" do
    opts = []

    config = [
      caravan: [
        strategy: Caravan.Cluster.DnsStrategy,
        config: [
          query: Keyword.get(opts, :consul_service, "example.net.consul"),
          node_sname: Keyword.get(opts, :node_sname, "somenode"),
          poll_interval: Keyword.get(opts, :poll_interval, 50_000),
          dns_client: Keyword.get(opts, :dns_client, Caravan.DnsClient)
        ]
      ]
    ]

    {:ok, _} = start_supervised({Cluster.Supervisor, [config, []]})
  end

  def connect_test(node) do
    assert :"connectnodetest-7000@somenode.foo.example.net" == node
    true
  end
end
