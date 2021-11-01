defmodule Snap.HTTPClient.Adapters.Finch do
  @moduledoc """
  Built in adapter using `Finch`.
  """
  @behaviour Snap.HTTPClient

  alias Snap.HTTPClient.Error
  alias Snap.HTTPClient.Response

  @default_pool_size 5

  @impl true
  def child_spec(config) do
    cluster = Keyword.fetch!(config, :cluster)
    url = Keyword.fetch!(config, :url)
    size = Keyword.get(config, :pool_size, @default_pool_size)

    finch_config = [
      name: connection_pool_name(cluster),
      pools: %{
        url => [size: size, count: 1]
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

  defp handle_response({:ok, %Finch.Response{} = finch_response}) do
    response = %Response{
      headers: finch_response.headers,
      status: finch_response.status,
      body: finch_response.body,
    }

    {:ok, response}
  end

  defp handle_response({:error, %{reason: reason} = origin}) when is_atom(reason) do
    {:error, Error.new(reason, origin)}
  end

  defp handle_response({:error, origin}) do
    {:error, Error.new(:unknown, origin)}
  end

  defp connection_pool_name(cluster) do
    Module.concat(cluster, Pool)
  end
end
