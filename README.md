# Caravan

Tools for running Distributed Elixir/Erlang with Nomad and Consul

The built-in Erlang distribution mechanisms are prefaced on using the Erlang
Port Mapper Daemon(EPMD), a process that is started with the VM and communicates with 
remote EPMD instances to determine what ports it's listening on.
While this method can work in some cloud environments, cloud scheduling technologies such as
Kubernetes or Nomad tend to make specific, random port assignments. Also, the
built-in method for forming a cluster is to use a plaintext .hosts file with
node names, which is very difficult to make work in a dynamic environment where
node membership can change frequently.

There are several libraries and strategies for using the Kubernetes API to
build a distributed cluster, but Consul provides us with a clean DNS api to
retrieve information, and works with many different kinds of container
schedulers (Nomad, Mesos, etc).

Caravan is split into two parts: The first is a set of modules that remove the
need for `epmd` by determining node ports from the node name. The idea and much of
the code is from the excellent article [Erlang (and Elixir) distribution
without
epmd](https://www.erlang-solutions.com/blog/erlang-and-elixir-distribution-without-epmd.html).
It's worth the read, and should explain what we're trying to accomplish with
the `Caravan.Epmd` module.

The second part utilizes [libcluster](https://github.com/bitwalker/libcluster)
to help with forming clusters automatically based on DNS SRV queries to
Consul.

View extended documentation on [Hex](https://hexdocs.pm/caravan/0.5.0).

## Installation

```elixir
{:caravan, "~> 1.0.0"},
```


