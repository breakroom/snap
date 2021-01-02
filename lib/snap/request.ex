defmodule Snap.Request do
  @moduledoc false
  @default_headers [{"content-type", "application/json"}, {"accept", "application/json"}]

  def request(cluster, method, path, body \\ nil, params \\ [], headers \\ [], opts \\ []) do
    config = cluster.config()
    auth = Map.fetch!(config, :auth)

    url =
      config
      |> Map.fetch!(:url)
      |> URI.merge(path)
      |> append_query_params(params)

    body = encode_body(body)
    headers = set_default_headers(headers)

    conn_pool_name = Snap.Cluster.Supervisor.connection_pool_name(cluster)

    start_time = System.os_time()

    with {:ok, {method, url, headers, body}} <- auth.sign(config, method, url, headers, body) do
      queue_time = System.os_time() - start_time

      response =
        Finch.build(method, url, headers, body)
        |> Finch.request(conn_pool_name, opts)

      query_time = System.os_time() - queue_time - start_time

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

  defp parse_response(response) do
    case response do
      {:ok, %Finch.Response{body: data, status: status}} when status >= 200 and status < 300 ->
        Jason.decode(data)

      {:ok, %Finch.Response{body: data}} ->
        with {:ok, json} <- Jason.decode(data) do
          exception = Snap.Exception.exception_from_response(json)
          {:error, exception}
        end

      err ->
        err
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

  defp encode_body(body) when is_map(body) do
    Jason.encode!(body)
  end

  defp encode_body(body), do: body

  def append_query_params(url, query_params \\ []) do
    uri = URI.parse(url)

    query_params_str = Map.get(uri, :query) || ""

    query_params = Enum.into(query_params, %{})

    query_params_str =
      query_params_str
      |> URI.decode_query()
      |> Map.merge(query_params)
      |> URI.encode_query()
      |> case do
        "" -> nil
        str -> str
      end

    uri
    |> Map.put(:query, query_params_str)
    |> URI.to_string()
  end

  def set_default_headers(headers) do
    @default_headers
    |> Enum.reduce(headers, fn {key, _value} = tuple, acc ->
      if List.keymember?(acc, key, 0) do
        acc
      else
        List.keystore(acc, key, 0, tuple)
      end
    end)
  end
end
