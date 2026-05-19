defmodule Snap.Search do
  @moduledoc """
  Performs searches against an ElasticSearch cluster.
  """
  alias Snap.Cluster.Namespace
  alias Snap.DeleteResponse
  alias Snap.Request
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
      {:ok, response} = Snap.Search.search(Cluster, "index", query)

      IO.inspect(response.took)
      Enum.each(response, fn hit -> IO.inspect(hit.score) end)
  """
  def search(cluster, index_or_alias, query, params \\ [], headers \\ [], opts \\ []) do
    namespaced_index =
      index_or_alias |> Namespace.add_namespace_to_index(cluster) |> Request.encode_segment()

    case cluster.post("/#{namespaced_index}/_search", query, params, headers, opts) do
      {:ok, response} -> {:ok, SearchResponse.new(response)}
      err -> err
    end
  end

  @spec scroll(
          cluster :: module(),
          scroll_id :: String.t(),
          scroll :: String.t(),
          params :: Keyword.t(),
          headers :: Keyword.t(),
          opts :: Keyword.t()
        ) :: {:ok, SearchResponse.t()} | Snap.Cluster.error()
  @doc """
  Continues a scroll search, retrieving the next batch of hits.

  Given a `scroll_id` returned from a previous `search/6` (with a `scroll`
  parameter) or `scroll/6` call, fetches the next batch of hits and returns a
  fresh `Snap.SearchResponse` with an updated `scroll_id`.

  The `scroll` argument is the lifetime of the scroll cursor on the server,
  refreshed on each call. Defaults to `"1m"`.

  This endpoint is global on the cluster — index namespaces do not apply.
  """
  def scroll(cluster, scroll_id, scroll \\ "1m", params \\ [], headers \\ [], opts \\ []) do
    body = %{"scroll" => scroll, "scroll_id" => scroll_id}

    case cluster.post("/_search/scroll", body, params, headers, opts) do
      {:ok, response} -> {:ok, SearchResponse.new(response)}
      err -> err
    end
  end

  @spec clear_scroll(
          cluster :: module(),
          scroll_id :: String.t(),
          params :: Keyword.t(),
          headers :: Keyword.t(),
          opts :: Keyword.t()
        ) :: {:ok, map()} | Snap.Cluster.error()
  @doc """
  Releases a scroll cursor on the server, freeing the resources it holds.

  Once a scroll is exhausted (or no longer needed), call this to clear the
  underlying search context. Scrolls also expire naturally based on the TTL
  passed to `search/6` or `scroll/6`, but explicit cleanup is preferred.
  """
  def clear_scroll(cluster, scroll_id, params \\ [], headers \\ [], opts \\ []) do
    encoded = Request.encode_segment(scroll_id)

    cluster.delete("/_search/scroll/#{encoded}", params, headers, opts)
  end

  @doc """
  Runs a count of the documents in an index, using an optional query.
  """
  def count(cluster, index_or_alias, query \\ %{}, params \\ [], headers \\ [], opts \\ []) do
    namespaced_index =
      index_or_alias |> Namespace.add_namespace_to_index(cluster) |> Request.encode_segment()

    case cluster.post("/#{namespaced_index}/_count", query, params, headers, opts) do
      {:ok, %{"count" => count}} -> {:ok, count}
      err -> err
    end
  end

  @doc """
  Runs a delete operation on an index, given a query.
  """
  def delete_by_query(cluster, index_or_alias, query, params \\ [], headers \\ [], opts \\ []) do
    namespaced_index =
      index_or_alias |> Namespace.add_namespace_to_index(cluster) |> Request.encode_segment()

    case cluster.post("/#{namespaced_index}/_delete_by_query", query, params, headers, opts) do
      {:ok, response} -> {:ok, DeleteResponse.new(response)}
      err -> err
    end
  end
end
