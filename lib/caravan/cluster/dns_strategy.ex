defmodule Caravan.Cluster.DnsStrategy do
  @moduledoc """
  Implements a libcluster strategy for node distribution based on Consul DNS.  By
  default it uses `:inet_res` to query the nameservers, though it can be
  overridden.

  ## Prerequisites
  First things first, is that you'll need to have Consul and Nomad setup. You'll
  need to create a service that will return SRV records with the hostname and
  distribution port. The [Consul documentation](https://www.consul.io/docs/agent/dns.html#standard-lookup)
  has directions on what needs to be setup and how to test with `dig`.

  Let's look at an example:
  ```
  'likes-service-3434@prod.socialmedia.consul`
  ```
  Above, `likes-service` is an app name. It will correspond with the :node_sname
  config option. The port is the last integer to the left of the '@'. You'll
  need this because our nodes will be using `Caravan.Epmd.Client` and
  `Caravan.Epmd.Dist_dist` to use the port number of the node name instead of
  being assigned a port randomly by `epmd`.

  Also note that the hostname of cluster nodes returned by Consul must be the
  same as that in the nodes `-name` parameter

  ## Configuration

  Here's a sample configuration
  ```
  config :libcluster,
    topologies: [
      caravan: [
        # The selected clustering strategy. Required.
        strategy: Caravan.Cluster.DnsStrategy,
        config: [
          #service name that returns the distribution port in a SRV record
          consul_service: "likes-service-dist.service.consul",
          #forms the base of the node name. App name is a good one.
          node_sname: "profile-service",
          #If you need to override the default DNS server. Must be an ip port
          #combo like below. Defaults to [] (dns are inherited from system)
          nameservers: [{"10.0.183.34", "8700"}],
          #The poll interval for the Consul service in milliseconds. Defaults to 5s
          poll_interval: 5_000
          #The module of the DNS client to use.
          dns_client: Caravan.DnsClient
        ],
      ]
    ]
  ```
  """

  use GenServer
  use Cluster.Strategy
  import Cluster.Logger
  alias Cluster.Strategy.State
  alias Caravan.Cluster.Config

  @impl Cluster.Strategy
  def start_link([%State{} = s]) do
    GenServer.start_link(__MODULE__, Config.new(s))
  end

  @impl GenServer
  def init(%Config{} = c) do
    Process.send_after(self(), :poll, 0)
    {:ok, c}
  end

  @impl GenServer
  def handle_info(
        :poll,
        %Config{query: q, poll_interval: pi, node_sname: node_sname, dns_client: dns} = state
      ) do
    q
    |> dns.get_nodes([])
    |> create_node_names(node_sname)
    |> remove_self()
    |> connect(state)

    Process.send_after(self(), :poll, pi)
    {:noreply, state}
  end

  defp remove_self(node_list) do
    List.delete(node_list, Node.self())
  end

  defp create_node_names(dns_records, node_name) do
    Enum.map(dns_records, fn {port, host} ->
      :"#{node_name}-#{port}@#{host}"
    end)
  end

  defp connect(nodes, %Config{connect: c, list_nodes: l, topology: t}) do
    if Application.get_env(:caravan, :debug, false) do
      debug(t, "found nodes #{inspect(nodes)}")
    end

    Cluster.Strategy.connect_nodes(t, c, l, nodes)
  end
end
