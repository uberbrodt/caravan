defmodule Caravan.Distribution.Supervisor do
  @moduledoc false

  alias Caravan.Distribution.SuperSupervisor

  @callback children() :: list(Supervisor.child_spec() | {module(), arg :: term()} | module())

  @doc false
  defmacro __using__(opts) do
    behaviour_mod = __MODULE__

    quote location: :keep, bind_quoted: [opts: opts, behaviour_mod: behaviour_mod] do
      # import Supervisor.Spec
      @behaviour Supervisor
      @behaviour behaviour_mod

      if Module.get_attribute(__MODULE__, :doc) == nil do
        @doc """
        Returns a specification to start this module under a supervisor.
        See `Supervisor`.
        """
      end

      def child_spec(init_arg) do
        default = %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [init_arg]},
          type: :supervisor
        }

        Supervisor.child_spec(default, unquote(Macro.escape(opts)))
      end

      def init(args) do
        super_supervisor_name = :"#{args[:base_name]}.Supervisor"

        children = [
          {SuperSupervisor, [{:name, super_supervisor_name}, {:children, children()} | args]}
        ]

        Supervisor.init(children, strategy: :one_for_one)
      end

      defdelegate start_link(args), to: behaviour_mod

      defoverridable child_spec: 1, start_link: 1
    end
  end

  def start_link(options) do
    base_name = Keyword.get(options, :name, nil)

    if is_nil(base_name) do
      raise "must specify :name in options, got: #{inspect(options)}"
    end

    options = Keyword.put(options, :base_name, base_name)

    Supervisor.start_link(__MODULE__, options, name: base_name)
  end

  def init(args) do
    super_supervisor_name = :"#{args[:base_name]}.Supervisor"
    child_specs = args[:children]

    children = [
      {SuperSupervisor, [{:name, super_supervisor_name}, {:children, child_specs} | args]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
