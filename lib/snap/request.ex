defmodule Snap.Request do
  def assemble_url(root_url, path, query_params) do
    root_uri =
      root_url
      |> URI.merge(path)
      |> URI.parse()

    root_query_params_str = Map.get(root_uri, :query) || ""

    query_params_str =
      root_query_params_str
      |> URI.decode_query()
      |> Map.merge(query_params)
      |> URI.encode_query()
      |> case do
        "" -> nil
        str -> str
      end

    root_uri
    |> Map.put(:query, query_params_str)
    |> URI.to_string()
  end
end
