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
    processes = Keyword.get(options, :process_specs)
    if processes == nil, do: raise(":processes cannot be nil")

    process_supervisor_name = :"#{base_name}.ProcessSupervisor"

    # IO.inspect(processes)

    monitors =
      Enum.map(processes, fn x ->
        Supervisor.child_spec(
          {Monitor,
           [
             process_spec: x,
             base_name: base_name,
             name: :"#{base_name}.#{x.name}.Monitor",
             process_supervisor: process_supervisor_name
           ]},
          id: :"#{base_name}.#{x.name}.Monitor"
        )
      end)

    children =
      [
        {DynamicSupervisor, strategy: :one_for_one, name: process_supervisor_name}
      ] ++ monitors

    Supervisor.init(children, strategy: :one_for_all)
  end
end
