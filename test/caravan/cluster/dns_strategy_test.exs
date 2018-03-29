defmodule Caravan.Cluster.DnsStrategyTest do
  use ExUnit.Case

  defmodule TestClient do
    def get_nodes(name, _opts) when is_binary(name) do
      [{7000, "somenode.foo.example.net"}]
    end
  end

  test "connect/1 gets correct node names" do
    config = [
      connect: {Caravan.Cluster.DnsStrategyTest, :connect_test, []},
      dns_client: Caravan.Cluster.DnsStrategyTest.TestClient,
      node_sname: "connectnodetest"
    ]

    {:ok, pid} = start_cluster_strategy(create_config(config))
    :timer.sleep(100)
  end

  test "nameservers processed correctly" do
    config = [nameservers: [{"10.0.254.75", 8600}]]
    {:ok, pid} = start_cluster_strategy(create_config(config))
    :timer.sleep(100)
    assert Process.alive?(pid) == true
  end

  def connect_test(node) do
    assert :"connectnodetest-7000@somenode.foo.example.net" == node
    true
  end

  defp create_config(opts) do
    config = [
      topology: :caravan_test,
      connect: Keyword.get(opts, :connect, {:net_kernel, :connect, []}),
      disconnect: {:net_kernel, :disconnect, []},
      list_nodes: {:erlang, :nodes, [:connected]},
      config: [
        consul_service: Keyword.get(opts, :consul_service, "example.net.consul"),
        node_sname: Keyword.get(opts, :node_sname, "somenode"),
        poll_interval: Keyword.get(opts, :poll_interval, 50_000),
        nameservers: Keyword.get(opts, :nameservers, []),
        dns_client: Keyword.get(opts, :dns_client, Caravan.DnsClient)
      ]
    ]
  end

  defp start_cluster_strategy(config) do
    start_supervised({Caravan.Cluster.DnsStrategy, config})
  end
end
