defmodule Caravan.Cluster.Config do
  @moduledoc """
  Config for `Caravan.Cluster.DnsStrategy.`

    - topology: topology name passed to `Cluster.Strategy.connect_nodes/4`
    - query: The name to query for SRV records. Something like:  `prod-likes-service-dist-consul`
    - dns_client: module implementing `Caravan.DnsClient`. Defaults to `Caravan.DnsClient.InetRes`.
    - node_sname: the base of a node name. App name is a good candidate.
    - connect: Override to use a different transport mechanism. Uses :libcluster defaults otherwise.
    - disconnect: Override to use a different transport mechanism. Uses :libcluster defaults otherwise.
    - list_nodes: Override to use a different transport mechanism. Uses :libcluster defaults otherwise.
    - poll_interval: poll the dns server on this interval. Defaults to 5_000
  """

  @default_poll_interval 5_000

  defstruct [
    :topology,
    :query,
    :dns_client,
    :node_sname,
    :connect,
    :disconnect,
    :list_nodes,
    :poll_interval
  ]

  def new(%Cluster.Strategy.State{
        topology: topo,
        connect: connect,
        disconnect: disconnect,
        list_nodes: list_nodes,
        config: config
      }) do
    query = Keyword.fetch!(config, :query)
    node_sname = Keyword.fetch!(config, :node_sname)
    poll_interval = Keyword.get(config, :poll_interval, @default_poll_interval)
    dns_client = Keyword.get(config, :dns_client, Caravan.DnsClient.InetRes)

    %__MODULE__{
      topology: topo,
      connect: connect,
      disconnect: disconnect,
      list_nodes: list_nodes,
      query: query,
      dns_client: dns_client,
      node_sname: node_sname,
      poll_interval: poll_interval
    }
  end
end
