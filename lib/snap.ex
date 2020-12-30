defmodule Snap do
  def get(cluster, path) do
    signed_request(cluster, "GET", path, [], nil)
  end

  def post(cluster, path, data) do
    signed_request(cluster, "POST", path, [], data)
  end

  def put(cluster, path, data) do
    signed_request(cluster, "PUT", path, [], data)
  end

  def delete(cluster, path) do
    signed_request(cluster, "DELETE", path, [], nil)
  end

  defp parse_response(response) do
    case response do
      {:ok, %{data: data, status: status}} when status >= 200 and status < 300 ->
        Jason.decode(data)

      {:ok, %{data: data}} ->
        with {:ok, json} <- Jason.decode(data) do
          exception = Snap.Exception.exception_from_response(json)
          {:error, exception}
        end

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
      |> parse_response()
    end
  end
end
