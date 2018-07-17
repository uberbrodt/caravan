defmodule Caravan.DnsClient.InetResTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Caravan.DnsClient.InetRes

  test "get_nodes/1" do
    [{port, name}] = InetRes.get_nodes("_xmpp-client._tcp.jabber.org")
    assert is_integer(port) == true
    assert is_binary(name) == true
  end
end
