defmodule Caravan.Distribution.SuperSupervisor do
  @moduledoc false
  use Supervisor

  alias Caravan.Distribution.Monitor

  def start_link(args) do
    name = args[:name]

    Supervisor.start_link(__MODULE__, args, name: name)
  end

  def init(options) do
    base_name = Keyword.fetch!(options, :base_name)
    processes = Keyword.get(options, :children)

    process_supervisor_name = :"#{base_name}.ProcessSupervisor"

    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: process_supervisor_name},
      {Monitor, [process_specs: processes, process_supervisor: process_supervisor_name]}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
