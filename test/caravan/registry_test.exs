defmodule Caravan.RegistryTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Caravan.ExampleServer
  alias Caravan.Registry

  describe "lookup/1" do
    test "returns [{pid, nil}] when name is registered" do
      test_pid = self()
      name = "foo"
      Registry.register(name)
      assert Registry.lookup(name) == [{test_pid, nil}]
    end

    test "returns [] when name is not registered" do
      assert Registry.lookup("foo") == []
    end
  end

  describe "unregister/1" do
    test "returns :ok when pid registered" do
      name = "foo"
      Registry.register(name)
      assert Registry.unregister(name) == :ok
    end

    test "reutrns :ok when pid is unregistered" do
      name = "foo"
      assert Registry.unregister(name) == :ok
    end
  end

  describe "unregister_name/1" do
    test "returns :ok when pid registered" do
      name = "foo"
      Registry.register(name)
      assert Registry.unregister_name(name) == :ok
    end

    test "reutrns :ok when pid is unregistered" do
      name = "foo"
      assert Registry.unregister_name(name) == :ok
    end

  end

  describe "start_link/2" do
    test "starts process" do
      {:ok, pid} = ExampleServer.start_link(name: "foo")
      assert is_pid(pid) == true
      assert :global.registered_names() != []
      assert is_pid(:global.whereis_name("foo")) == true
    end

    test "checks to see if it's supposed to be on node" do
    end

    test "crashes if the child process crashes with unknown reason" do
      name = "foo"

      test_pid = self()

      {:ok, monitor_pid} = start_supervised({ExampleServer, [name: name, test_pid: test_pid]})
      ref = Process.monitor(monitor_pid)

      assert_receive({:started_process, {_, name, pid}}, 5_000)

      :ok = ExampleServer.crash(Caravan.Registry.via_tuple(name))
      assert_receive({:caught_exit, {:EXIT, ^pid, :crashed}}, 5_000)
      assert_receive({:DOWN, ^ref, :process, ^monitor_pid, :crashed}, 5_000)

      assert Process.alive?(monitor_pid) == false
      assert Process.alive?(pid) == false
    end

    test "restarts process if node it is running on disappears" do
      [node1, node2] = Caravan.Test.Cluster.start_cluster(2, self())
      assert_receive({:started_process, {^node1, "permanent_example", pid1}}, 5_000)
      assert_receive({:started_process, {^node1, "transient_example", pid2}}, 5_000)
      assert_receive({:already_started, {^node2, "permanent_example", _}}, 5_000)
      assert_receive({:already_started, {^node2, "transient_example", _}}, 5_000)

      :ok = LocalCluster.stop_nodes([node1])

      assert_receive({:caught_exit, {:EXIT, ^pid1, :noconnection}}, 5_000)
      assert_receive({:caught_exit, {:EXIT, ^pid2, :noconnection}}, 5_000)

      assert_receive({:started_process, {_, "permanent_example", restarted_pid1}}, 5_000)
      assert_receive({:started_process, {_, "transient_example", restarted_pid2}}, 5_000)

      {:ok, restarted_pid} = Caravan.ExampleServer.check("permanent_example")
      pid = Caravan.Registry.ConflictHandler.get_child_pid(Registry.via_tuple("permanent_example"))
      assert restarted_pid == pid
    end

    test "checks to see if process is running on it's ideal node" do
      [node1, _node2] = Caravan.Test.Cluster.start_cluster(2, self())

      assert_receive({:check_process_location, {^node1, "permanent_example"}}, 20_000)
    end

    test "moves process to ideal node" do
      name = "permanent_example"
      [node1, _, _, _, node5] = Caravan.Test.Cluster.start_cluster(5, self())

      assert_receive({:started_process, {^node1, ^name, orig_pid}}, 5_000)
      assert_receive({:already_started, {^node5, ^name, _}}, 5_000)
      assert :erlang.node(orig_pid) == node1

      assert_receive({:moving_node_exit, {target_node, target_node}}, 40_000)
      assert_receive({:started_process, {^target_node, ^name, new_pid}}, 5_000)

      assert_receive({:track_moved_process, {^node1, :found, ^name, ^new_pid}}, 120_000)

      looked_up_pid = Caravan.Registry.whereis_name(name)
      assert looked_up_pid == new_pid
      assert :erlang.node(new_pid) == target_node
    end
  end

  describe "test cluster" do
    test "something" do
      [node1, node2] = Caravan.Test.Cluster.start_cluster(2, self())

      assert_receive({:started_process, {^node1, "permanent_example", pid1}}, 5_000)
      assert_receive({:started_process, {^node1, "transient_example", pid2}}, 5_000)
      assert_receive({:already_started, {^node2, "permanent_example", _}}, 5_000)
      assert_receive({:already_started, {^node2, "transient_example", _}}, 5_000)

      permanent_pid = Caravan.Registry.whereis_name("permanent_example")
      transient_pid = Caravan.Registry.whereis_name("transient_example")

      assert permanent_pid == pid1
      assert transient_pid == pid2
    end
  end
end
