defmodule Snap.Bulk do
  @moduledoc """
  Supports streaming bulk operations against a `Snap.Cluster`.
  """

  @default_page_size 5000
  @default_page_wait 15_000

  alias Snap.Bulk.Actions

  @doc """
  Performs a bulk operation.

  Takes an `Enumerable` of action structs, where each struct is one of:

  * `Snap.Bulk.Action.Create`
  * `Snap.Bulk.Action.Index`
  * `Snap.Bulk.Action.Update`
  * `Snap.Bulk.Action.Delete`

  ```
  actions = [
    %Snap.Bulk.Action.Create{_id: 1, doc: %{foo: "bar"}},
    %Snap.Bulk.Action.Create{_id: 2, doc: %{foo: "bar"}},
    %Snap.Bulk.Action.Create{_id: 3, doc: %{foo: "bar"}}
  ]

  actions
  |> Snap.Bulk.perform(Cluster, "index")
  ```

  It chunks the `Enumerable` into pages, and pauses between pages for
  Elasticsearch to catch up. Uses `Stream` under the hood, so you can lazily
  feed it a stream of actions, such as out of an `Ecto.Repo` to bulk load
  documents from an SQL database.

  If no errors occur on any page it returns `:ok`. If any errors occur, on
  any page, it returns `{:error, %Snap.BulkError{}}`, containing a list of
  the errors. It will continue to the end of the stream, even if errors
  occur.

  Options:

  * `page_size` - defines the size of each page, defaulting to 5000 actions.
  * `page_wait` - defines wait period between pages in ms, defaulting to
    15000ms.
  * `max_errors` - aborts when the number of errors returned exceedes this
    count (defaults to `nil`, which will run to the end)

  Any other options, such as `pipeline: "foo"` are passed through as query
  parameters to the [Bulk
  API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html)
  endpoint.
  """
  @spec perform(
          stream :: Enumerable.t(),
          cluster :: module(),
          index :: String.t(),
          opts :: Keyword.t()
        ) ::
          :ok | Snap.Cluster.error() | {:error, Snap.BulkError.t()}
  def perform(stream, cluster, index, opts) do
    page_size = Keyword.get(opts, :page_size, @default_page_size)
    page_wait = Keyword.get(opts, :page_wait, @default_page_wait)
    max_errors = Keyword.get(opts, :max_errors, nil)
    request_params = Keyword.drop(opts, [:page_size, :page_wait, :max_errors])

    stream
    |> Stream.chunk_every(page_size)
    |> Stream.intersperse({:wait, page_wait})
    |> Stream.transform(0, &process_chunk(&1, cluster, index, request_params, &2, max_errors))
    |> Enum.to_list()
    |> handle_result()
  end

  defp process_chunk({:wait, 0}, _cluster, _index, _params, error_count, _max_errors) do
    {[], error_count}
  end

  defp process_chunk({:wait, wait}, _cluster, _index, _params, error_count, _max_errors) do
    :ok = :timer.sleep(wait)

    {[], error_count}
  end

  defp process_chunk(_actions, _cluster, _index, _params, error_count, max_errors)
       when is_integer(max_errors) and error_count > max_errors do
    {:halt, error_count}
  end

  defp process_chunk(actions, cluster, index, params, error_count, _max_errors) do
    body = Actions.encode(actions)

    headers = [{"content-type", "application/x-ndjson"}]

    result = Snap.post(cluster, "/#{index}/_bulk", body, params, headers)

    add_errors =
      case result do
        {:ok, %{"errors" => true, "items" => items}} ->
          process_errors(items)

        {:ok, _} ->
          []

        {:error, error} ->
          [error]
      end

    error_count = error_count + Enum.count(add_errors)

    {add_errors, error_count}
  end

  defp handle_result([]), do: :ok

  defp handle_result(errors) do
    err = Snap.BulkError.exception(errors)

    {:error, err}
  end

  defp process_errors(items) do
    items
    |> Enum.map(&process_item/1)
    |> Enum.reject(&is_nil/1)
  end

  defp process_item(%{"create" => %{"error" => error} = item}) when is_map(error) do
    Snap.Exception.exception_from_response(item)
  end

  defp process_item(%{"index" => %{"error" => error} = item}) when is_map(error) do
    Snap.Exception.exception_from_response(item)
  end

  defp process_item(%{"update" => %{"error" => error} = item}) when is_map(error) do
    Snap.Exception.exception_from_response(item)
  end

  defp process_item(%{"delete" => %{"error" => error} = item}) when is_map(error) do
    Snap.Exception.exception_from_response(item)
  end

  defp process_item(_), do: nil
end
