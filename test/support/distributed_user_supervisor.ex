defmodule Caravan.TestSupport.DistributedUserSupervisor do
  @moduledoc false
  use Caravan.Distribution.Supervisor
  alias Caravan.TestSupport.UserServer

  def children do
    [{UserServer, []}]
  end
end
