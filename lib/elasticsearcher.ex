defmodule Elasticsearcher do
  def get(cluster, path) do
    cluster.with_connection(fn pid ->
      Elasticsearcher.Connection.request(pid, "GET", path, [], nil)
    end)
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
end
