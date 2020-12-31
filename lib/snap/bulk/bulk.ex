defmodule Snap.Bulk do
  @default_page_size 5000
  @default_page_wait 15_000

  alias Snap.Bulk.Actions

  def perform(stream, cluster, index, opts) do
    page_size = Keyword.get(opts, :page_size, @default_page_size)
    page_wait = Keyword.get(opts, :page_wait, @default_page_wait)

    stream
    |> Stream.chunk_every(page_size)
    |> Stream.intersperse({:wait, page_wait})
    |> Stream.flat_map(&process_chunk(&1, cluster, index))
    |> Enum.to_list()
    |> handle_result()
  end

  defp process_chunk({:wait, 0}, _cluster, _index) do
    []
  end

  defp process_chunk({:wait, wait}, _cluster, _index) do
    :ok = :timer.sleep(wait)

    []
  end

  defp process_chunk(actions, cluster, index) do
    body = Actions.encode(actions)

    headers = [{"content-type", "application/x-ndjson"}]

    result = Snap.request(cluster, "POST", "/#{index}/_bulk", headers, body)

    case result do
      {:ok, %{"errors" => true, "items" => items}} ->
        process_errors(items)

      {:ok, _} ->
        []

      {:error, errors} ->
        errors
    end
  end

  defp handle_result([]), do: :ok
  defp handle_result(errors), do: {:error, errors}

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
