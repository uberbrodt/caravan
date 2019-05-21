defmodule Caravan.RegistryTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Caravan.ExampleServer

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

      assert Caravan.ExampleServer.check("permanent_example") == {:ok, restarted_pid1}
    end

    test "checks to see if process is running on it's ideal node" do
      [node1, _node2] = Caravan.Test.Cluster.start_cluster(2, self())

      assert_receive({:check_process_location, {^node1, "permanent_example"}}, 20_000)
    end

    test "moves process to ideal node" do
      [node1, node2] = Caravan.Test.Cluster.start_cluster(2, self())

      assert_receive({:started_process, {^node1, "permanent_example", orig_pid}}, 5_000)
      IO.inspect(orig_pid, label: "permanent_example pid")
      assert_receive({:already_started, {^node2, "permanent_example", _}}, 5_000)
      assert :erlang.node(orig_pid) == node1

      assert_receive({:moving_node_exit, {target_node, target_node}}, 40_000)
      assert_receive({:started_process, {^target_node, "permanent_example", new_pid}}, 5_000)

      looked_up_pid = Caravan.Registry.whereis_name("permanent_example")
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
