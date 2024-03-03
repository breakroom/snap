defmodule Snap.Search do
  @moduledoc """
  Performs searches against an ElasticSearch cluster.
  """
  alias Snap.SearchResponse
  alias Snap.Cluster.Namespace

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
      {:ok, response} = Snap.Search.search(Cluster, "index", query)

      IO.inspect(response.took)
      Enum.each(response, fn hit -> IO.inspect(hit.score) end)
  """
  def search(cluster, index_or_alias, query, params \\ [], headers \\ [], opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index_or_alias, cluster)

    case cluster.post("/#{namespaced_index}/_search", query, params, headers, opts) do
      {:ok, response} -> {:ok, SearchResponse.new(response)}
      err -> err
    end
  end

  @doc """
  Gets the next page of results in a scroll which was initiated by passing
  the scroll param into a search request, and parses the result into a
  `Snap.SearchResponse`.

  `Snap.SearchResponse` implements `Enumerable`, so you can count and iterate
  directly on the struct.

  """
  def scroll_req(cluster, scroll_id, ttl \\ "1m", params \\ [], headers \\ [], opts \\ []) do
    body = %{
      scroll: ttl,
      scroll_id: scroll_id
    }

    case cluster.post("/_search/scroll", body, params, headers, opts) do
      {:ok, response} -> {:ok, SearchResponse.new(response)}
      err -> err
    end
  end

  @doc """
  Return all the results for a query via a set of scrolls, lazily as a stream.

  It is highly recommended that you set size to something large 10k is the max
  And that you sort by _doc for efficiency reasons
  https://www.elastic.co/guide/en/elasticsearch/reference/current/paginate-search-results.html#scroll-search-results

    ## Examples

      query = %{query: %{match_all: %{}}, size: 10_000, sort: ["_doc"]}
      stream = Snap.Search.scroll(Cluster, "index", query)

  """
  def scroll(cluster, index_or_alias, query, params \\ [], headers \\ [], opts \\ []) do
    params = [scroll: "1m"] |> Keyword.merge(params)

    Stream.resource(
      fn ->
        nil
      end,
      fn scroll_id ->
        results =
          if is_nil(scroll_id) do
            {:ok, results} =
              Snap.Search.search(cluster, index_or_alias, query, params, headers, opts)

            results
          else
            {:ok, results} = Snap.Search.scroll_req(cluster, scroll_id)
            results
          end

        hits = results.hits.hits

        if Enum.empty?(hits) do
          {:halt, nil}
        else
          new_scroll_id = results.scroll_id
          # pass the scroll id so we can now scroll
          {results, new_scroll_id}
        end
      end,
      fn _ ->
        nil
      end
    )
  end

  @doc """
  Runs a count of the documents in an index, using an optional query.
  """
  def count(cluster, index_or_alias, query \\ %{}, params \\ [], headers \\ [], opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index_or_alias, cluster)

    case cluster.post("/#{namespaced_index}/_count", query, params, headers, opts) do
      {:ok, %{"count" => count}} -> {:ok, count}
      err -> err
    end
  end
end
