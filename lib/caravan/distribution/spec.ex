defmodule Caravan.Distribution.Spec do
  @moduledoc false

  @type t :: %__MODULE__{
          id: String.t(),
          name: atom,
          supervisor_spec: Supervisor.child_spec()
        }

  defstruct [:name, :id, :supervisor_spec]

  @spec new(name :: atom, spec :: Supervisor.child_spec() | {module(), arg :: term()} | module()) ::
          __MODULE__.t()
  def new(name, spec) do
    sup_spec = Supervisor.child_spec(spec, [])
    %__MODULE__{name: name, id: "#{Atom.to_string(name)}.Id", supervisor_spec: sup_spec}
  end
end
