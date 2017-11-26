defmodule Caravan.DnsClient do

  def get_nodes(name, opts \\ []) when is_binary(name) do
    lookup(String.to_charlist(name), :in, :srv, opts)
  end

  defp lookup(name, class, type, opts) do
    results = :inet_res.lookup(name, class, type, opts)
    Enum.map(results, fn ({_, _, port, name}) ->
      {port, to_string(name)}
    end)
  end


end
