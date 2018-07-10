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

  @default_poll_interval 5_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init([state]) do
    # state = %State{
    #   topology: Keyword.fetch!(opts, :topology),
    #   connect: Keyword.fetch!(opts, :connect),
    #   disconnect: Keyword.fetch!(opts, :disconnect),
    #   list_nodes: Keyword.fetch!(opts, :list_nodes),
    #   config: Keyword.fetch!(opts, :config)
    # }

    consul_svc = Keyword.fetch!(state.config, :consul_service)
    node_sname = Keyword.fetch!(state.config, :node_sname)
    poll_interval = Keyword.get(state.config, :poll_interval, @default_poll_interval)

    nameservers =
      Keyword.get(state.config, :nameservers, [])
      |> process_dns_servers()

    dns_client = Keyword.get(state.config, :dns_client, Caravan.DnsClient)

    state = %{state | :meta => {poll_interval, consul_svc, node_sname, nameservers, dns_client}}
    Process.send_after(self(), :poll, 0)
    {:ok, state}
  end

  def handle_info(:poll, %State{meta: {pi, q, node_sname, [], dns}} = state) do
    q
    |> dns.get_nodes([])
    |> create_node_names(node_sname)
    |> remove_self()
    |> connect(state)

    Process.send_after(self(), :poll, pi)
    {:noreply, state}
  end

  def handle_info(:poll, %State{meta: {pi, q, node_sname, nameservers, dns}} = state) do
    q
    |> dns.get_nodes(nameservers: nameservers)
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

  defp connect(nodes, %State{connect: c, list_nodes: l, topology: t}) do
    if Application.get_env(:caravan, :debug, false) do
      debug(t, "found nodes #{inspect(nodes)}")
    end

    Cluster.Strategy.connect_nodes(t, c, l, nodes)
  end

  defp process_dns_servers([]) do
    []
  end

  # Conform :ip datatype has a tuple of binaries for ip and port, so handle it
  # here to send to :inet_res
  defp process_dns_servers(servers_list) when is_list(servers_list) do
    Enum.map(servers_list, fn {ip, port} ->
      ip_tuple =
        ip
        |> String.split(".")
        |> Enum.map(&String.to_integer/1)
        |> List.to_tuple()

      port_int =
        case port do
          p when is_binary(p) -> String.to_integer(p)
          p when is_integer(p) -> p
        end

      {ip_tuple, port_int}
    end)
  end
end
