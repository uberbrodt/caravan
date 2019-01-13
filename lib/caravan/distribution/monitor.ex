defmodule Caravan.Distribution.Monitor do
  @moduledoc false
  use GenServer

  def start_link(args) do
    name = args[:name]
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def init(args) do
    child_specs = args[:process_specs]
    process_supervisor = args[:process_supervisor]
    base_name = args[:base_name]

    for %{id: id, name: name, supervisor_spec: spec} <- child_specs do
      lock_id = {id, Node.self()}
      scoped_name = :"#{base_name}.#{name}"

      :global.trans(lock_id, fn ->
        with :undefined <- :global.whereis_name(scoped_name),
             {:ok, pid} <- DynamicSupervisor.start_child(process_supervisor, spec),
             :yes <- :global.register_name(scoped_name, pid),
             do: pid
      end)
    end

    {:ok, %{specs: child_specs}}
  end
end
