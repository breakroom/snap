defmodule Elasticsearcher.Cluster.Supervisor do
  use Supervisor
  @timeout 60_000

  def start_link(cluster, otp_app, config) do
    Supervisor.start_link(__MODULE__, {cluster, otp_app, config}, name: cluster)
  end

  def with_connection(cluster, fun) do
    :poolboy.transaction(
      pool_name(cluster),
      fun,
      @timeout
    )
  end

  def config(cluster) do
    Elasticsearcher.Config.get(config_name(cluster))
  end

  ## Callbacks

  @doc false
  @impl Supervisor
  def init({cluster, _otp_app, config}) do
    children = [
      :poolboy.child_spec(
        pool_name(cluster),
        poolboy_child_spec(cluster, config),
        poolboy_worker_args(config)
      ),
      {Elasticsearcher.Config, {config_name(cluster), config}}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp poolboy_child_spec(cluster, config) do
    size = Map.get(config, :pool_size, 5)
    overflow = Map.get(config, :pool_overflow, 2)

    [
      name: {:local, pool_name(cluster)},
      worker_module: Elasticsearcher.Connection,
      size: size,
      overflow: overflow
    ]
  end

  defp poolboy_worker_args(config) do
    url = Map.get(config, :url, "http://localhost:9200")
    %URI{host: host, port: port, scheme: scheme} = URI.parse(url)
    scheme = String.to_atom(scheme)

    [
      scheme: scheme,
      host: host,
      port: port
    ]
  end

  defp pool_name(cluster) do
    Module.concat(cluster, Pool)
  end

  defp config_name(cluster) do
    Module.concat(cluster, Config)
  end
end
