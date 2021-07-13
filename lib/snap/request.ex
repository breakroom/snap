defmodule Snap.Request do
  require Logger

  @moduledoc false
  @default_headers [{"content-type", "application/json"}, {"accept", "application/json"}]

  def request(cluster, method, path, body \\ nil, params \\ [], headers \\ [], opts \\ []) do
    config = cluster.config()
    auth = Keyword.get(config, :auth, Snap.Auth.Plain)

    url =
      config
      |> Keyword.fetch!(:url)
      |> URI.merge(path)
      |> append_query_params(params)

    body = encode_body(body)
    headers = set_default_headers(headers)

    conn_pool_name = Snap.Cluster.Supervisor.connection_pool_name(cluster)

    start_time = System.monotonic_time()

    with {:ok, {method, url, headers, body}} <- auth.sign(config, method, url, headers, body) do
      response =
        Finch.build(method, url, headers, body)
        |> Finch.request(conn_pool_name, opts)

      response_time = System.monotonic_time() - start_time

      result = parse_response(response)

      decode_time = System.monotonic_time() - response_time - start_time
      total_time = response_time + decode_time

      Logger.debug(fn ->
        "Elasticsearch #{method} request path=#{path} response=#{format_time_to_ms(response_time)}ms decode=#{format_time_to_ms(decode_time)}ms total=#{format_time_to_ms(total_time)}ms"
      end)

      event = telemetry_prefix(cluster) ++ [:request]

      measurements = %{
        response_time: response_time,
        decode_time: decode_time,
        total_time: total_time
      }

      uri = URI.parse(url)

      metadata = telemetry_metadata(method, uri, headers, body, result)

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
          exception = Snap.ResponseError.exception_from_response(json)
          {:error, exception}
        end

      err ->
        err
    end
  end

  defp telemetry_prefix(cluster) do
    config = cluster.config()

    Keyword.get_lazy(config, :telemetry_prefix, fn ->
      otp_app = cluster.otp_app()
      [otp_app, :snap]
    end)
  end

  defp telemetry_metadata(method, uri, _headers, body, result) do
    %{method: method, host: uri.host, port: uri.port, path: uri.path, body: body, result: result}
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

  defp format_time_to_ms(t) do
    System.convert_time_unit(t, :native, :millisecond)
  end
end
