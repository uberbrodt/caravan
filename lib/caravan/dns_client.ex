defmodule Caravan.DnsClient do
  @moduledoc """
  A client for fetching SRV records from DNS and returning.
  """

  @doc """
  Accepts a valid dns record name. Returns a list of {port, host} which can then be used to
  construct a node name.
  """
  @callback get_nodes(name :: binary) :: [{integer, binary}]
end
