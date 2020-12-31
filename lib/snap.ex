defmodule Snap do
  @default_headers [{"content-type", "application/json"}]
  def get(cluster, path, opts \\ []) do
    signed_request(cluster, "GET", path, @default_headers, nil, opts)
  end

  def post(cluster, path, data, opts \\ []) do
    body = encode_body(data)
    signed_request(cluster, "POST", path, @default_headers, body, opts)
  end

  def put(cluster, path, data, opts \\ []) do
    body = encode_body(data)
    signed_request(cluster, "PUT", path, @default_headers, body, opts)
  end

  def delete(cluster, path, opts \\ []) do
    signed_request(cluster, "DELETE", path, @default_headers, nil, opts)
  end

  def request(cluster, method, path, headers, body, opts \\ []) do
    signed_request(cluster, method, path, headers, body, opts)
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

  defp signed_request(cluster, method, path, headers, body, opts) do
    config = cluster.config()
    auth = Map.fetch!(config, :auth)

    start_time = System.os_time()

    with {:ok, {method, path, headers, body}} <- auth.sign(config, method, path, headers, body) do
      {response, queue_time, query_time} =
        cluster.with_connection(fn pid ->
          queue_time = System.os_time() - start_time
          response = Snap.Connection.request(pid, method, path, headers, body)
          query_time = System.os_time() - queue_time - start_time

          {response, queue_time, query_time}
        end)

      result = parse_response(response)

      decode_time = System.os_time() - query_time - queue_time - start_time
      total_time = queue_time + query_time + decode_time

      event = telemetry_prefix(cluster) ++ [:request]

      measurements = %{
        queue_time: queue_time,
        query_time: query_time,
        decode_time: decode_time,
        total_time: total_time
      }

      metadata = telemetry_metadata(method, path, headers, body, result)

      :telemetry.execute(event, measurements, metadata)

      result
    end
  end

  defp telemetry_prefix(cluster) do
    config = cluster.config()

    Map.get_lazy(config, :telemetry_prefix, fn ->
      otp_app = cluster.otp_app()
      [otp_app, :snap]
    end)
  end

  defp telemetry_metadata(method, path, _headers, body, result) do
    %{method: method, path: path, body: body, result: result}
  end

  defp encode_body(body) when is_nil(body), do: nil
  defp encode_body(body) when is_binary(body), do: body

  defp encode_body(body) when is_map(body) do
    Jason.encode!(body)
  end
end
