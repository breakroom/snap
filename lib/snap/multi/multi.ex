defmodule Snap.Multi do
  @moduledoc """
  Provides a high level abstraction over the [Multi Search
  API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-multi-search.html)
  which allows the user to perform multiple searches in a single request.

  Example usage:

      Multi.new()
      |> Multi.add(query_1, id: "query-1")
      |> Multi.add(query_2, id: "query-2")
      |> Multi.run(Cluster, index)

  This returns a `Snap.Multi.Response`, with a `searches` field containing a
  list of responses.

      {:ok, %Snap.Multi.Response{searches: [
        {"query-1", %Snap.SearchResponse{...}},
        {"query-2", %Snap.SearchResponse{...}}
      ]}}

  Each query can be named, using any value you like, by passing an `id: "foo"`
  into `Multi.add`. The list in `Snap.Multi.Response` contains tuple pairs where
  the first value is the ID and the second is the result of the query.

  If you choose not to name a query the ID in the tuple will be `nil`.

  If your query IDs are unique you can convert this to a `Map` for easy lookup
  later using `Enum.into(response.searches, %{})`.
  """

  defstruct searches: []

  @type t :: %__MODULE__{searches: list()}

  alias Snap.Cluster.Namespace
  alias Snap.Multi.Response
  alias Snap.Multi.Search

  @doc """
  Build a `Snap.Multi` request.
  """
  @spec new() :: t()
  def new() do
    %__MODULE__{}
  end

  @doc """
  Append to a `Snap.Multi` request. The `body` is required. If you pass an `id`
  into the headers, this will be used to name the query in the responses list
  and won't be passed through as a header in the request.
  """
  @spec add(t(), map(), Keyword.t()) :: t()
  def add(%__MODULE__{} = multi, body, headers \\ []) do
    {id, headers} = Keyword.pop(headers, :id)
    search = %Search{id: id, body: body, headers: headers}

    %__MODULE__{multi | searches: multi.searches ++ [search]}
  end

  @doc """
  Perform the `Snap.Multi` request. This returns `{:ok, Snap.Multi.Response}` or
  an error.
  """
  @spec run(t(), atom(), String.t(), Keyword.t(), Keyword.t(), Keyword.t()) ::
          {:ok, Snap.Multi.Response.t()} | {:error, Snap.Cluster.error()}
  def run(%__MODULE__{} = multi, cluster, index_or_alias, params \\ [], headers \\ [], opts \\ []) do
    ids = build_ids(multi.searches)
    body = encode(multi)
    headers = headers ++ [{"content-type", "application/x-ndjson"}]
    namespaced_index = Namespace.add_namespace_to_index(index_or_alias, cluster)

    case cluster.post("/#{namespaced_index}/_msearch", body, params, headers, opts) do
      {:ok, response} -> {:ok, Response.new(response, ids)}
      err -> err
    end
  end

  defp encode(%__MODULE__{} = multi) do
    multi.searches
    |> Enum.flat_map(&encode_search/1)
  end

  defp encode_search(%Search{headers: headers, body: body}) do
    [encode_headers(headers), "\n", encode_body(body), "\n"]
  end

  defp encode_headers(headers) do
    headers
    |> Enum.into(%{})
    |> Jason.encode!(pretty: false)
  end

  defp encode_body(body) do
    Jason.encode!(body, pretty: false)
  end

  defp build_ids(searches) do
    Enum.map(searches, & &1.id)
  end
end
