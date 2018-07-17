defmodule Caravan.DnsClient do
  @callback get_nodes(name :: binary) :: [{integer, binary}]
end
