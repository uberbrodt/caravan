defmodule Caravan.Epmd.Dist_dist do
  @moduledoc """
  Implements the Erlang distribution protocol. Forwards most calls to
  `:inet_tcp_dist` with the exception of `listen/1` which uses `Caravan.Epmd`
  to get the distribution port instead of calling out to `epmd`. The `_dist`
  part of the module name is required for it to work, but will be used like this
  `-proto_dist Caravan.Epmd.Dist`
  """
  alias Caravan.Epmd
  def listen(name) do
    # Here we figure out what port we want to listen on.

    port = Epmd.dist_port name

    # Set both "min" and "max" variables, to force the port number to
    # this one.
    :ok = :application.set_env :kernel, :inet_dist_listen_min, port
    :ok = :application.set_env :kernel, :inet_dist_listen_max, port

    # Finally run the real function!
    :inet_tcp_dist.listen name
  end

  def select(node) do
    :inet_tcp_dist.select(node)
  end

  def accept(listen) do
    :inet_tcp_dist.accept(listen)
  end

  def accept_connection(accept_pid, socket, my_node, allowed, setup_time) do
    :inet_tcp_dist.accept_connection(accept_pid, socket, my_node, allowed, setup_time)
  end

  def setup(node, type, my_node, long_or_short_names, setup_time) do
    :inet_tcp_dist.setup(node, type, my_node, long_or_short_names, setup_time)
  end

  def close(listen) do
    :inet_tcp_dist.close(listen)
  end

  def is_node_name(node)  do
    :inet_tcp_dist.is_node_name(node)
  end
end
