defmodule Caravan.Distribution.SupervisorTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Caravan.Distribution.Supervisor, as: DistributedSupervisor

  test "can start supervisor with atom name" do
    {:ok, pid} = DistributedSupervisor.start_link(name: DistributedUserSupervisor)
  end
end
