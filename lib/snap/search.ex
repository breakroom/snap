defmodule Snap.Search do
  @moduledoc """
  Performs searches against an ElasticSearch cluster.
  """
  alias Snap.SearchResponse

  @spec search(
          cluster :: module(),
          index_or_alias :: String.t(),
          query :: map(),
          params :: Keyword.t(),
          headers :: Keyword.t(),
          opts :: Keyword.t()
        ) :: {:ok, SearchResponse.t()} | Snap.Cluster.error()
  @doc """
  Makes a search against an ElasticSearch cluster and parses the response.

  Performs a search against an index using a POST request, and parses the
  response into a `Snap.SearchResponse`.

  `Snap.SearchResponse` implements `Enumerable`, so you can count and iterate
  directly on the struct.

  ## Examples

      query = %{query: %{match_all: %{}}}
      {:ok, response} = Snap.Search(Cluster, "index", query)

      IO.inspect(response.took)
      Enum.each(fn hit -> IO.inspect(hit._score) end)
  """
  def search(cluster, index_or_alias, query, params \\ [], headers \\ [], opts \\ []) do
    case cluster.post("/#{index_or_alias}/_search", query, params, headers, opts) do
      {:ok, response} -> {:ok, SearchResponse.new(response)}
      err -> err
    end
  end
end
