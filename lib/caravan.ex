defmodule Caravan do
  @moduledoc """
  Tools for running Distributed Elixir/Erlang with Nomad and Consul

  # Caravan

  The built-in Erlang distribution mechanisms are prefaced on using the Erlang
  Port Mapper Daemon, a process that runs on each box with an Erlang node and
  assigns it a port. On startup you feed your node with a list of hosts to
  connect to or connect manually in your application code. While this method
  can work in some cloud environments, cloud scheduling technologies such as
  Kubernetes or Nomad make it very inflexible and error prone.

  There are several libraries and strategies for using the Kubernetes API to
  build a distributed cluster, but Consul provides us with a clean DNS api to
  retrieve information, while Nomad handles monitoring and scheduling services.

  Caravan is split into two parts: The first is a set of modules that remove the
  need for `epmd` by determing node ports by the node name. The idea and much of
  the code is from the excellent article [Erlang (and Elixir) distribution
  without
  epmd](https://www.erlang-solutions.com/blog/erlang-and-elixir-distribution-without-epmd.html).
  It's worth the read, and should explain what we're trying to accomplish with
  the `Caravan.Epmd` module.

  The second part utilizes [libcluster](https://github.com/bitwalker/libcluster)
  to help with forming clusters automatically based on DNS SRV queries to
  Consul.

  ## Getting started with custom Erlang distribution

  Erlang has some command line options to overwrite the default distribution
  mechanism. To use Caravan's implementations, you would do something similar to
  this
  ```
  iex --erl "-proto_dist Elixir.Caravan.Epmd.Dist -start_epmd false -epmd_module Elixir.Caravan.Epmd.Client" --sname "node3434" -S mix
  ```
  For testing locally, you'll either have to run `elixirc` on the above
  modules to create the required `.beam` files, or you can pass an additional
  flag to `--erl`:
  ```
  -pa _build/dev/lib/caravan/ebin
  ```
  Note: building a release with Distillery will not require the `-pa` flag.

  """
end
