defmodule Snap.Indexes do
  alias Snap.Bulk
  alias Snap

  def create(cluster, index, mapping, opts \\ []) do
    Snap.put(cluster, "/#{index}", mapping, opts)
  end

  def delete(cluster, index, opts \\ []) do
    Snap.delete(cluster, "/#{index}", opts)
  end

  def hotswap(stream, cluster, alias, mapping, opts \\ []) do
    index = generate_index_name(alias)

    with {:ok, _} <- create(cluster, index, mapping, opts),
         :ok <- Bulk.perform(stream, cluster, index, opts),
         :ok <- refresh(cluster, index, opts),
         :ok <- alias(cluster, index, alias, opts) do
      :ok
    end
  end

  def refresh(cluster, index, opts \\ []) do
    with {:ok, _} <- Snap.post(cluster, "/#{index}/_refresh", nil, opts) do
      :ok
    end
  end

  def alias(cluster, index, alias, opts \\ []) do
    with {:ok, indexes} <- list_starting_with(cluster, alias, opts) do
      indexes = Enum.reject(indexes, &(&1 == index))

      remove_actions =
        Enum.map(indexes, fn i ->
          %{"remove" => %{"index" => i, "alias" => alias}}
        end)

      actions = %{
        "actions" => remove_actions ++ [%{"add" => %{"index" => index, "alias" => alias}}]
      }

      with {:ok, _response} <- Snap.post(cluster, "/_aliases", actions), do: :ok
    end
  end

  def list(cluster, opts \\ []) do
    opts = Keyword.put(opts, :format, "json")

    with {:ok, indexes} <- Snap.get(cluster, "/_cat/indices", opts) do
      indexes =
        indexes
        |> Enum.map(& &1["index"])
        |> Enum.sort()

      {:ok, indexes}
    end
  end

  def list_starting_with(cluster, prefix, opts \\ []) do
    opts = Keyword.put(opts, :format, "json")

    with {:ok, indexes} <- Snap.get(cluster, "/_cat/indices", opts) do
      prefix = prefix |> to_string() |> Regex.escape()
      {:ok, regex} = Regex.compile("^#{prefix}-[0-9]+$")

      indexes =
        indexes
        |> Enum.map(& &1["index"])
        |> Enum.filter(&Regex.match?(regex, &1))
        |> Enum.sort()

      {:ok, indexes}
    end
  end

  defp generate_index_name(alias) do
    ts = generate_alias_timestamp()
    "#{alias}-#{ts}"
  end

  defp generate_alias_timestamp do
    DateTime.to_unix(DateTime.utc_now(), :microsecond)
  end
end
