defmodule Caravan.Cluster.ConfigTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Caravan.Cluster.Config
  alias Cluster.Strategy.State

  test "new/1 sets :connect" do
    result =
      create_state(%{connect: :foo})
      |> Config.new()

    assert result.connect == :foo
  end

  test "new/1 sets :toplology" do
    result =
      create_state(%{topology: "whatever"})
      |> Config.new()

    assert result.topology == "whatever"
  end

  test "new/1 sets :disconnect" do
    result =
      create_state(%{disconnect: :foo})
      |> Config.new()

    assert result.disconnect == :foo
  end

  test "new/1 sets :list_nodes" do
    result =
      create_state(%{list_nodes: :foo})
      |> Config.new()

    assert result.list_nodes == :foo
  end

  test "new/1 sets :query" do
    result =
      create_state(%{config: [query: :foo]})
      |> Config.new()

    assert result.query == :foo
  end

  test "new/1 sets :dns_client" do
    result =
      create_state(%{config: [dns_client: :foo]})
      |> Config.new()

    assert result.dns_client == :foo
  end

  test "new/1 sets :node_sname" do
    result =
      create_state(%{config: [node_sname: :foo]})
      |> Config.new()

    assert result.node_sname == :foo
  end

  test "new/1 sets :poll_interval" do
    result =
      create_state(%{config: [poll_interval: :foo]})
      |> Config.new()

    assert result.poll_interval == :foo
  end

  test "new/1 raises KeyError if :query not set" do
    assert_raise(KeyError, fn -> Config.new(%State{config: [node_sname: "something"]}) end)
  end

  test "new/1 raises KeyError if :node_sname not set" do
    assert_raise(KeyError, fn -> Config.new(%State{config: [query: "something"]}) end)
  end

  defp create_state(%{config: in_config} = in_state) do
    config =
      Keyword.merge(
        [
          query: "profile-service-dist.service.consul",
          node_sname: "profile-service"
        ],
        in_config
      )

    result = struct(State, in_state)
    %{result | config: config}
  end

  defp create_state(in_state) do
    state = %State{
      topology: :caravan,
      connect: {:net_kernel, :connect_node, []},
      disconnect: {:erlang, :disconnect_node, []},
      list_nodes: {:erlang, :nodes, [:connected]},
      config: [
        query: "profile-service-dist.service.consul",
        node_sname: "profile-service"
      ]
    }

    Map.merge(state, in_state)
  end
end
