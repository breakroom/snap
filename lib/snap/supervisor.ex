defmodule Snap.Cluster.Supervisor do
  @moduledoc false

  use Supervisor
  @default_pool_size 5
  @default_conn_opts []

  def start_link(cluster, otp_app, config) do
    Supervisor.start_link(__MODULE__, {cluster, otp_app, config}, name: cluster)
  end

  def config(cluster) do
    Snap.Config.get(config_name(cluster))
  end

  def connection_pool_name(cluster) do
    Module.concat(cluster, Pool)
  end

  ## Callbacks

  @doc false
  @impl Supervisor
  def init({cluster, _otp_app, config}) do
    children = [
      {Finch, finch_config(cluster, config)},
      {Snap.Config, {config_name(cluster), config}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp finch_config(cluster, config) do
    url = Keyword.fetch!(config, :url)
    size = Keyword.get(config, :pool_size, @default_pool_size)
    conn_opts = Keyword.get(config, :conn_opts, @default_conn_opts)

    [
      name: connection_pool_name(cluster),
      pools: %{
        url => [size: size, count: 1, conn_opts: conn_opts]
      }
    ]
  end

  defp config_name(cluster) do
    Module.concat(cluster, Config)
  end
end
