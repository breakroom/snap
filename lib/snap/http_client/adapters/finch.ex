defmodule Snap.HTTPClient.Adapters.Finch do
  @moduledoc """
  Built in adapter using `Finch`.

  You can also configure this adapter by explicitly setting the `http_client_adapter`
  in the `Snap.Cluster` configuration with a tuple `{Snap.HTTPClient.Adapters.Finch, config}`.
  For example:

  ```
  config :my_app, MyApp.Cluster,
    http_client_adapter: {Snap.HTTPClient.Adapters.Finch, pool_size: 20}
  ```

  You can check the `t:config/0` for docs about the available configurations.
  """
  @behaviour Snap.HTTPClient

  require Logger

  alias Snap.HTTPClient.Error
  alias Snap.HTTPClient.Response

  @typedoc """
  Available options for configuring the Finch adapter. For more information about the options,
  you can check [Finch's official docs](https://hexdocs.pm/finch/Finch.html#start_link/1-pool-configuration-options).

    * `pool_size`: Set the pool size. Defaults to `5`.
    * `conn_opts`: Connection options passed to `Mint.HTTP.connect/4`. Defaults to `[]`.
  """
  @type config :: [
          pool_size: pos_integer(),
          conn_opts: keyword()
        ]

  @default_pool_size 5
  @default_conn_opts []

  @impl true
  def child_spec(config) do
    if not Code.ensure_loaded?(Finch) do
      Logger.error("""
      Can't start Snap.HTTPClient.Adapters.Finch because :finch is not available.

      Please make sure to add :finch as a dependency:
          {:finch, "~> 0.8"}

      Or set your own Snap.HTTPClient:
          config :my_app, MyApp.Cluster, http_client_adapter: MyHTTPClient
      """)

      raise "missing finch dependency"
    end

    Application.ensure_all_started(:finch)

    cluster = Keyword.fetch!(config, :cluster)
    url = Keyword.fetch!(config, :url)
    size = Keyword.get(config, :pool_size, @default_pool_size)
    conn_opts = Keyword.get(config, :conn_opts, @default_conn_opts)

    finch_config = [
      name: connection_pool_name(cluster),
      pools: %{
        url => [size: size, count: 1, conn_opts: conn_opts]
      }
    ]

    {Finch, finch_config}
  end

  @impl true
  def request(cluster, method, url, headers, body, opts \\ []) do
    conn_pool_name = connection_pool_name(cluster)

    method
    |> Finch.build(url, headers, body)
    |> Finch.request(conn_pool_name, opts)
    |> handle_response()
  end

  defp handle_response({:ok, finch_response}) do
    response = %Response{
      headers: finch_response.headers,
      status: finch_response.status,
      body: finch_response.body
    }

    {:ok, response}
  end

  defp handle_response({:error, %{reason: reason} = origin}) when is_atom(reason) do
    {:error, Error.new(reason, origin)}
  end

  defp handle_response({:error, origin}) do
    {:error, Error.unknown(origin)}
  end

  defp connection_pool_name(cluster) do
    Module.concat(cluster, Pool)
  end
end
