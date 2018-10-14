defmodule Caravan.Distribution.SuperSupervisor do
  @moduledoc false
  use Supervisor

  def init(options) do
    base_name = Keyword.fetch!(options, :base_name)

    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: :"#{base_name}.ProcessesSupervisor"}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
