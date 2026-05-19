defmodule Snap.Scroll do
  @moduledoc """
  Streams documents from a search query using the [scroll API](https://www.elastic.co/guide/en/elasticsearch/reference/current/paginate-search-results.html#scroll-search-results).

  Returns a lazy `Stream` that yields `Snap.Hit` structs one at a time,
  transparently fetching subsequent batches via `Snap.Search.scroll/6` as
  needed, then clearing the scroll cursor via `Snap.Search.clear_scroll/5`
  when the stream is exhausted, terminated early, or raises.

  Unlike most functions in `Snap`, errors are not returned as `{:error, _}`
  tuples — lazy enumerables can't surface errors mid-iteration. Instead, any
  underlying request failure raises the corresponding exception (typically
  `Snap.ResponseError`) when the consumer pulls the next element.
  """
  alias Snap.Hits
  alias Snap.Search
  alias Snap.SearchResponse

  @spec stream(
          cluster :: module(),
          index_or_alias :: String.t(),
          query :: map(),
          opts :: Keyword.t()
        ) :: Enumerable.t()
  @doc """
  Returns a lazy stream of `Snap.Hit` structs matching `query` in `index_or_alias`.

  ## Options

  - `:scroll` — TTL string for the server-side cursor, refreshed on each
    continuation. Defaults to `"1m"`.
  - `:params` — extra query params merged into the initial search and each
    scroll continuation.
  - `:headers` — passed through to the underlying requests.
  - `:opts` — request opts passed through to the underlying HTTP client.

  ## Examples

      query = %{"query" => %{"match_all" => %{}}, "size" => 100}

      Snap.Scroll.stream(Cluster, "products", query)
      |> Stream.map(& &1.source)
      |> Enum.each(&IO.inspect/1)
  """
  def stream(cluster, index_or_alias, query, opts \\ []) do
    scroll = Keyword.get(opts, :scroll, "1m")
    params = Keyword.get(opts, :params, [])
    headers = Keyword.get(opts, :headers, [])
    request_opts = Keyword.get(opts, :opts, [])

    start_fun = fn -> {:start, query} end

    next_fun = fn
      {:start, query} ->
        initial_params = Keyword.put(params, :scroll, scroll)

        case Search.search(cluster, index_or_alias, query, initial_params, headers, request_opts) do
          {:ok, %SearchResponse{hits: %Hits{hits: []}, scroll_id: sid}} ->
            {:halt, sid}

          {:ok, %SearchResponse{hits: %Hits{hits: hits}, scroll_id: sid}} ->
            {hits, {:continue, sid}}

          {:error, exc} ->
            raise exc
        end

      {:continue, scroll_id} ->
        case Search.scroll(cluster, scroll_id, scroll, params, headers, request_opts) do
          {:ok, %SearchResponse{hits: %Hits{hits: []}, scroll_id: sid}} ->
            {:halt, sid || scroll_id}

          {:ok, %SearchResponse{hits: %Hits{hits: hits}, scroll_id: sid}} ->
            {hits, {:continue, sid || scroll_id}}

          {:error, exc} ->
            raise exc
        end
    end

    after_fun = fn
      {:continue, scroll_id} when is_binary(scroll_id) ->
        Search.clear_scroll(cluster, scroll_id, params, headers, request_opts)
        :ok

      scroll_id when is_binary(scroll_id) ->
        Search.clear_scroll(cluster, scroll_id, params, headers, request_opts)
        :ok

      _ ->
        :ok
    end

    Stream.resource(start_fun, next_fun, after_fun)
  end
end
