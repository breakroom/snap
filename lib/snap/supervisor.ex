defmodule Snap.Cluster.Supervisor do
  @moduledoc false

  use Supervisor

  alias Snap.HTTPClient

  def start_link(cluster, otp_app, config) do
    Supervisor.start_link(__MODULE__, {cluster, otp_app, config}, name: cluster)
  end

  def config(cluster) do
    Snap.Config.get(config_name(cluster))
  end

  ## Callbacks

  @doc false
  @impl Supervisor
  def init({cluster, _otp_app, config}) do
    children =
      [
        {Snap.Config, {config_name(cluster), config}}
      ] ++ maybe_initialize_http_client(cluster, config)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp config_name(cluster) do
    Module.concat(cluster, Config)
  end

  defp maybe_initialize_http_client(cluster, config) do
    config = Keyword.put(config, :cluster, cluster)

    case HTTPClient.child_spec(config) do
      :skip -> []
      http_client_child_spec -> [http_client_child_spec]
    end
  end
end
