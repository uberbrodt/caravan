defmodule Caravan.Registry.MonitorTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "attempts to start process afer 5 attempts in of :track_moved_process" do
    name = "permanent_example"
    mfa = {Caravan.ExampleServer, :start_link, [[name: "permanent_example"]]}
    node = Node.self()
    opts = [test_pid: self()]

    {:ok, pid} = start_supervised({Caravan.Registry.Monitor, [name: name, mfa: mfa, opts: opts]})
    assert_receive({:started_process, {^node, ^name, _}}, 5_000)

    Caravan.Registry.unregister(name)
    send(pid, {:track_moved_process, 5})

    assert_receive({:started_process, {^node, ^name, _}}, 5_000)
  end

  def start_link(name, mfa) do
  end
end
