defmodule Snap.HTTPClient do
  @moduledoc """
  Behaviour for the HTTP client used by the `Snap.Cluster`.

  By default, it uses the `Snap.HTTPClient.Adapters.Finch` for making requests.

  You can configure the Cluster with your own adapter:

  ```
  config :my_app, MyApp.Cluster,
    http_client_adapter: MyHTTPClientAdapter
  ```
  """

  alias Snap.HTTPClient.Error
  alias Snap.HTTPClient.Response

  @type t :: module()
  @type method :: :get | :post | :put | :delete | String.t()
  @type url :: String.t()
  @type headers :: [{key :: String.t(), value :: String.t()}]
  @type body :: iodata()
  @type child_spec :: Supervisor.child_spec() | {module(), Keyword.t()} | module()

  @doc """
  Returns a specification to start this module under the `Snap` supervisor tree.

  If the adapter doesn't need to start in the supervisor tree, you can return `:skip`.
  """
  @callback child_spec(config :: Keyword.t()) :: child_spec() | :skip

  @doc """
  Executes the request with the configured adapter.
  """
  @callback request(
              cluster :: module(),
              method :: atom(),
              url,
              headers,
              body,
              opts :: Keyword.t()
            ) :: {:ok, Response.t()} | {:error, Error.t()}

  def child_spec(config) do
    adapter(config).child_spec(config)
  end

  def request(cluster, method, url, headers, body, opts \\ []) do
    adapter(cluster).request(cluster, method, url, headers, body, opts)
  end

  defp adapter(cluster_config) when is_list(cluster_config) do
    Keyword.get(cluster_config, :http_client_adapter, Snap.HTTPClient.Adapters.Finch)
  end

  defp adapter(cluster) do
    adapter(cluster.config())
  end
end
