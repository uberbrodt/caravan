defmodule Caravan.TestSupport.UserServer do
  @moduledoc false
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    state = args
    {:ok, state}
  end
end
