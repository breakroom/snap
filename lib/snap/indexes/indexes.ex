defmodule Snap.Indexes do
  @moduledoc """
  Helper functions around index management.
  """
  alias Snap.Bulk
  alias Snap

  @doc """
  Creates an index.
  """
  @spec create(module(), String.t(), map(), Keyword.t()) :: Snap.Cluster.result()
  def create(cluster, index, mapping, opts \\ []) do
    Snap.put(cluster, "/#{index}", mapping, [], [], opts)
  end

  @doc """
  Deletes an index.
  """
  @spec delete(module(), String.t(), Keyword.t()) :: Snap.Cluster.result()
  def delete(cluster, index, opts \\ []) do
    Snap.delete(cluster, "/#{index}", [], [], opts)
  end

  @doc """
  Creates and loads a new index, switching the alias to it with zero-downtime.

  Takes an `Enumerable` of `Snap.Bulk` actions, and builds a new index from
  it. Refreshes it, updates the alias to it, and cleans up the old indexes,
  leaving the previous one behind.

  May return `t:Snap.Cluster.error/0` or a `Snap.BulkError` containing a list
  of failed bulk actions.
  """
  @spec hotswap(Enumerable.t(), module(), String.t(), map(), Keyword.t()) ::
          :ok | Snap.Cluster.error() | {:error, Snap.BulkError.t()}
  def hotswap(stream, cluster, alias, mapping, opts \\ []) do
    index = generate_index_name(alias)

    with {:ok, _} <- create(cluster, index, mapping),
         :ok <- Bulk.perform(stream, cluster, index, opts),
         :ok <- refresh(cluster, index),
         :ok <- alias(cluster, index, alias),
         :ok <- cleanup(cluster, alias, 2, opts) do
      :ok
    end
  end

  @doc """
  Refreshes an index.
  """
  @spec refresh(cluster :: module(), index :: String.t(), opts :: Keyword.t()) ::
          :ok | Snap.Cluster.error()
  def refresh(cluster, index, opts \\ []) do
    with {:ok, _} <- Snap.post(cluster, "/#{index}/_refresh", nil, [], [], opts) do
      :ok
    end
  end

  @doc """
  Creates an alias for a versioned index, removing any existing aliases.
  """
  @spec alias(module(), String.t(), String.t(), Keyword.t()) :: :ok | Snap.Cluster.error()
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

  @doc """
  Lists all the indexes in the cluster.
  """
  @spec list(module(), Keyword.t()) :: {:ok, list(String.t())} | Snap.Cluster.error()
  def list(cluster, opts \\ []) do
    with {:ok, indexes} <- Snap.get(cluster, "/_cat/indices", [format: "json"], [], opts) do
      indexes =
        indexes
        |> Enum.map(& &1["index"])
        |> Enum.sort()

      {:ok, indexes}
    end
  end

  @doc """
  Lists all the timestamp versioned indexes starting with the prefix.
  """
  @spec list_starting_with(module(), String.t(), Keyword.t()) ::
          {:ok, list(String.t())} | Snap.Cluster.error()
  def list_starting_with(cluster, prefix, opts \\ []) do
    with {:ok, indexes} <- Snap.get(cluster, "/_cat/indices", [format: "json"], [], opts) do
      prefix = prefix |> to_string() |> Regex.escape()
      {:ok, regex} = Regex.compile("^#{prefix}-[0-9]+$")

      indexes =
        indexes
        |> Enum.map(& &1["index"])
        |> Enum.filter(&Regex.match?(regex, &1))
        |> Enum.sort_by(&sort_index_by_timestamp/1)

      {:ok, indexes}
    end
  end

  @doc """
  Deletes older timestamped indexes.
  """
  @spec cleanup(module(), String.t(), non_neg_integer(), Keyword.t()) ::
          :ok | Snap.Cluster.error()
  def cleanup(cluster, alias, preserve \\ 2, opts \\ []) do
    with {:ok, indexes} <- list_starting_with(cluster, alias, opts) do
      indexes
      |> Enum.sort_by(&sort_index_by_timestamp/1, &>=/2)
      |> Enum.drop(preserve)
      |> Enum.reduce_while(:ok, fn index, ok ->
        case delete(cluster, index, opts) do
          {:ok, _} -> {:cont, ok}
          {:error, _} = err -> {:halt, err}
        end
      end)
    end
  end

  defp generate_index_name(alias) do
    ts = generate_alias_timestamp()
    "#{alias}-#{ts}"
  end

  defp generate_alias_timestamp do
    DateTime.to_unix(DateTime.utc_now(), :microsecond)
  end

  defp sort_index_by_timestamp(index) do
    index
    |> String.split("-")
    |> Enum.at(-1)
    |> String.to_integer()
  end
end
