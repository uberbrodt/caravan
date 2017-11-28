# Caravan

Tools for running Distributed Elixir/Erlang with Nomad and Consul

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

View extended documentation on [Hex](https://hexdocs.pm/caravan/0.5.0).

**Note:** Caravan is still pre 1.0, so there may be breaking changes until
that time.

## Installation

```elixir
{:caravan, "~> 0.5.0"},
```


