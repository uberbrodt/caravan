defmodule Caravan.Distribution.Supervisor do
  @moduledoc false

  alias Caravan.Distribution.SuperSupervisor

  @doc """
  See `start_link/2` for options.
  """
  def child_spec(options \\ []) do
    options = Keyword.put_new(options, :id, __MODULE__)

    %{
      id: options[:id],
      start: {__MODULE__, :start_link, [Keyword.drop(options, [:id])]},
      type: :supervisor
    }
  end

  def start_link(options) do
    base_name = Keyword.get(options, :name, nil)

    if is_nil(base_name) do
      raise "must specify :name in options, got: #{inspect(options)}"
    end

    options = Keyword.put(options, :base_name, base_name)

    Supervisor.start_link(SuperSupervisor, options, name: :"#{base_name}.Supervisor")
  end

  def start_child(supervisor, child_spec) do
  end
end
