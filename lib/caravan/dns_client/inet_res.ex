defmodule Caravan.DnsClient.InetRes do
  @moduledoc false
  @behaviour Caravan.DnsClient

  @impl Caravan.DnsClient
  def get_nodes(name) when is_binary(name) do
    lookup(String.to_charlist(name), :in, :srv, [])
  end

  defp lookup(name, class, type, opts) do
    results = :inet_res.lookup(name, class, type, opts)

    Enum.map(results, fn {_, _, port, name} ->
      {port, to_string(name)}
    end)
  end
end
