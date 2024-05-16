defmodule Snap.Request do
  @moduledoc """
  Supports making arbitrary requests against `Snap.Cluster`.

  In most cases you're better off using the functions in `Snap.Cluster`
  directly, e.g. `c:Snap.Cluster.get/4`.
  """
  require Logger

  alias Snap.HTTPClient

  @default_headers [
    {"content-type", "application/json"},
    {"accept", "application/json"}
  ]

  @doc """
  Makes an HTTP request against a `Snap.Cluster`
  """
  def request(cluster, method, path, body \\ nil, params \\ [], headers \\ [], opts \\ []) do
    config = cluster.config()
    auth = Keyword.get(config, :auth, Snap.Auth.Plain)
    json_library = cluster.json_library()

    url =
      config
      |> Keyword.fetch!(:url)
      |> URI.merge(path)
      |> append_query_params(params)

    body = encode_body(body, json_library)
    headers = set_default_headers(headers)

    start_time = System.monotonic_time()

    with {:ok, {method, url, headers, body}} <- auth.sign(config, method, url, headers, body) do
      response = HTTPClient.request(cluster, method, url, headers, body, opts)

      response_time = System.monotonic_time() - start_time

      result = parse_response(response, json_library)

      decode_time = System.monotonic_time() - response_time - start_time
      total_time = response_time + decode_time

      Logger.debug(fn ->
        """
        Elasticsearch #{http_method_to_string(method)} request \
        path=#{path} \
        response=#{format_time_to_ms(response_time)}ms \
        decode=#{format_time_to_ms(decode_time)}ms \
        total=#{format_time_to_ms(total_time)}ms\
        """
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

  defp parse_response(response, json_library) do
    case response do
      {:ok, %HTTPClient.Response{body: data, status: status}}
      when status >= 200 and status < 300 ->
        json_library.decode(data)

      {:ok, %HTTPClient.Response{body: data} = response} ->
        # If there's no valid JSON treat the error as an HTTPError.
        case json_library.decode(data) do
          {:ok, json} ->
            exception = Snap.ResponseError.exception_from_json(json)
            {:error, exception}

          {:error, _} ->
            exception = Snap.HTTPError.exception_from_response(response)
            {:error, exception}
        end

      {:error, %HTTPClient.Error{}} = err ->
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
    method_str = http_method_to_string(method)

    %{
      method: method_str,
      host: uri.host,
      port: uri.port,
      path: uri.path,
      body: body,
      result: result
    }
  end

  defp encode_body(body, json_library) when is_map(body), do: json_library.encode!(body)
  defp encode_body(body, _json_library), do: body

  defp append_query_params(url, query_params) do
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

  defp set_default_headers(headers) do
    @default_headers
    |> Enum.reduce(headers, fn {key, _value} = tuple, acc ->
      if List.keymember?(acc, key, 0) do
        acc
      else
        List.keystore(acc, key, 0, tuple)
      end
    end)
  end

  defp http_method_to_string(method) when is_atom(method) do
    method
    |> Atom.to_string()
    |> String.upcase()
  end

  defp format_time_to_ms(t) do
    System.convert_time_unit(t, :native, :millisecond)
  end
end
