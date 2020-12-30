defmodule Snap do
  def get(cluster, path) do
    signed_request(cluster, "GET", path, [], nil)
    |> parse_response()
  end

  defp parse_response(response) do
    case response do
      {:ok, %{data: data}} ->
        Jason.decode(data)

      err ->
        err
    end
  end

  defp signed_request(cluster, method, path, headers, body) do
    config = cluster.config()
    auth = Map.fetch!(config, :auth)

    with {:ok, {method, path, headers, body}} <- auth.sign(config, method, path, headers, body) do
      cluster.with_connection(fn pid ->
        Snap.Connection.request(pid, method, path, headers, body)
      end)
    end
  end
end
