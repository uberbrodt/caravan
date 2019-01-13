defmodule Caravan.Distribution.SupervisorTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Caravan.Distribution.Supervisor, as: DistributedSupervisor
  alias Caravan.TestSupport.UserServer

  test "can start supervisor with atom name" do
    {:ok, _} =
      DistributedSupervisor.start_link(
        name: DistributedUserSupervisor,
        processes: [UserServer]
      )
  end

  test "can start supervisor using behaviour" do
  end

  test "get_child/1" do
    {:ok, _} = Caravan.TestSupport.DistributedUserSupervisor.start_link(name: Foo)
    pid = Caravan.TestSupport.DistributedUserSupervisor.get_child(UserServer)
    assert is_pid(pid) == true
  end
end
