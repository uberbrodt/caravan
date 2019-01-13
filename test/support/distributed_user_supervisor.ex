defmodule Caravan.TestSupport.DistributedUserSupervisor do
  @moduledoc false
  use Caravan.Distribution.Supervisor
  alias Caravan.TestSupport.UserServer
  alias Caravan.Distribution.Spec

  @impl true
  def children do
    [Spec.new(UserServer, {UserServer, []})]
  end
end
