defmodule Snap.Indexes do
  @moduledoc """
  Helper functions around index management.
  """
  alias Snap
  alias Snap.Bulk
  alias Snap.BulkError
  alias Snap.Cluster
  alias Snap.Cluster.Namespace

  @doc """
  Creates an index.
  """
  @spec create(module(), String.t(), map()) :: Cluster.result()
  @spec create(module(), String.t(), map(), Keyword.t()) :: Cluster.result()
  def create(cluster, index, mapping, opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)
    Snap.put(cluster, "/#{namespaced_index}", mapping, [], [], opts)
  end

  @doc """
  Deletes an index.
  """
  @spec delete(module(), String.t()) :: Cluster.result()
  @spec delete(module(), String.t(), Keyword.t()) :: Cluster.result()
  def delete(cluster, index, opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)
    Snap.delete(cluster, "/#{namespaced_index}", [], [], opts)
  end

  @doc """
  Get an index's mapping.
  """
  @spec get_mapping(module(), String.t()) :: Cluster.result()
  @spec get_mapping(module(), String.t(), Keyword.t()) :: Cluster.result()
  def get_mapping(cluster, index, opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)
    Snap.get(cluster, "/#{namespaced_index}/_mapping", [], [], opts)
  end

  @doc """
  Updates the given index's mapping.

  See: https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-get-settings.html
  """
  @spec update_mapping(module(), String.t(), map()) :: Cluster.result()
  @spec update_mapping(module(), String.t(), map(), Keyword.t()) :: Cluster.result()
  def update_mapping(cluster, index, mapping, opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)
    Snap.put(cluster, "/#{namespaced_index}/_mapping", mapping, [], [], opts)
  end

  @doc """
  Get all of the index's settings.

  See: https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-get-settings.html
  """
  @spec get_settings(module(), String.t()) :: Cluster.result()
  @spec get_settings(module(), String.t(), Keyword.t()) :: Cluster.result()
  @spec get_settings(module(), String.t(), Keyword.t(), Keyword.t()) :: Cluster.result()
  def get_settings(cluster, index, params \\ [], opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)
    Snap.get(cluster, "/#{namespaced_index}/_settings", params, [], opts)
  end

  @doc """
  Get an index's setting using a comma separate list or wildcard expression

  See: https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-get-settings.html
  """
  @spec get_setting(module(), String.t(), String.t()) :: Cluster.result()
  @spec get_setting(module(), String.t(), String.t(), Keyword.t()) :: Cluster.result()
  @spec get_setting(module(), String.t(), String.t(), Keyword.t(), Keyword.t()) ::
          Cluster.result()
  def get_setting(cluster, index, setting, params \\ [], opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)
    Snap.get(cluster, "/#{namespaced_index}/_settings/#{setting}", params, [], opts)
  end

  @doc """
  Update an index's settings.

  See: https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-update-settings.html
  """
  @spec update_settings(module(), String.t(), map()) :: Cluster.result()
  @spec update_settings(module(), String.t(), map(), Keyword.t()) :: Cluster.result()
  @spec update_settings(module(), String.t(), map(), Keyword.t(), Keyword.t()) :: Cluster.result()
  def update_settings(cluster, index, settings, params \\ [], opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)
    Snap.put(cluster, "/#{namespaced_index}/_settings", settings, params, [], opts)
  end

  @doc """
  Get an index's shard stores.

  See: https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-shards-stores.html
  """
  @spec get_shard_stores(module(), String.t()) :: Cluster.result()
  @spec get_shard_stores(module(), String.t(), Keyword.t()) :: Cluster.result()
  @spec get_shard_stores(module(), String.t(), Keyword.t(), Keyword.t()) :: Cluster.result()
  def get_shard_stores(cluster, index, params \\ [], opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)
    Snap.get(cluster, "/#{namespaced_index}/_shard_stores", params, [], opts)
  end

  @doc """
  Get an index's stats.

  See: https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-stats.html
  """
  @spec get_stats(module(), String.t()) :: Cluster.result()
  @spec get_stats(module(), String.t(), Keyword.t()) :: Cluster.result()
  @spec get_stats(module(), String.t(), Keyword.t(), Keyword.t()) :: Cluster.result()
  def get_stats(cluster, index, params \\ [], opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)
    Snap.get(cluster, "/#{namespaced_index}/_stats", params, [], opts)
  end

  @doc """
  Get an index's stats using a metric. Metric is a comma separated list of metrics.

  See: https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-stats.html
  """
  @spec get_stat(module(), String.t(), String.t()) :: Cluster.result()
  @spec get_stat(module(), String.t(), String.t(), Keyword.t()) :: Cluster.result()
  @spec get_stat(module(), String.t(), String.t(), Keyword.t(), Keyword.t()) :: Cluster.result()
  def get_stat(cluster, index, metric, params \\ [], opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)
    Snap.get(cluster, "/#{namespaced_index}/_stats/#{metric}", params, [], opts)
  end

  @doc """
  Closes an open index.

  See: https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-close.html
  """
  @spec close(module(), String.t()) :: Cluster.result()
  @spec close(module(), String.t(), Keyword.t()) :: Cluster.result()
  @spec close(module(), String.t(), Keyword.t(), Keyword.t()) :: Cluster.result()
  def close(cluster, index, params \\ [], opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)
    Snap.post(cluster, "/#{namespaced_index}/_close", [], params, [], opts)
  end

  @doc """
  Opens a closed index.

  See: https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-open-close.html
  """
  @spec open(module(), String.t()) :: Cluster.result()
  @spec open(module(), String.t(), Keyword.t()) :: Cluster.result()
  @spec open(module(), String.t(), Keyword.t(), Keyword.t()) :: Cluster.result()
  def open(cluster, index, params \\ [], opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)
    Snap.post(cluster, "/#{namespaced_index}/_open", [], params, [], opts)
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
          :ok | Cluster.error() | {:error, BulkError.t()}
  def hotswap(stream, cluster, alias, mapping, opts \\ []) do
    index = generate_index_name(alias)
    create_opts = [wait_for_active_shards: "all"]

    with {:ok, _} <- create(cluster, index, mapping, create_opts),
         :ok <- Bulk.perform(stream, cluster, index, opts),
         :ok <- refresh(cluster, index),
         :ok <- alias(cluster, index, alias) do
      cleanup(cluster, alias, 2, opts)
    end
  end

  @doc """
  Refreshes an index.
  """
  @spec refresh(cluster :: module(), index :: String.t(), opts :: Keyword.t()) ::
          :ok | Cluster.error()
  def refresh(cluster, index, opts \\ []) do
    namespaced_index = Namespace.add_namespace_to_index(index, cluster)

    with {:ok, _} <- Snap.post(cluster, "/#{namespaced_index}/_refresh", nil, [], [], opts) do
      :ok
    end
  end

  @doc """
  Creates an alias for a versioned index, removing any existing aliases.
  """
  @spec alias(module(), String.t(), String.t(), Keyword.t()) :: :ok | Cluster.error()
  def alias(cluster, index, alias, opts \\ []) do
    with {:ok, indexes} <- list_starting_with(cluster, alias, opts) do
      indexes = Enum.reject(indexes, &(&1 == index))

      namespaced_index = Namespace.add_namespace_to_index(index, cluster)
      namespaced_alias = Namespace.add_namespace_to_index(alias, cluster)

      remove_actions =
        Enum.map(indexes, fn i ->
          %{
            "remove" => %{
              "index" => Namespace.add_namespace_to_index(i, cluster),
              "alias" => namespaced_alias
            }
          }
        end)

      actions = %{
        "actions" =>
          remove_actions ++
            [%{"add" => %{"index" => namespaced_index, "alias" => namespaced_alias}}]
      }

      with {:ok, _response} <- Snap.post(cluster, "/_aliases", actions), do: :ok
    end
  end

  @doc """
  Lists all the indexes in the cluster.
  """
  @spec list(module(), Keyword.t()) :: {:ok, list(String.t())} | Cluster.error()
  def list(cluster, opts \\ []) do
    with {:ok, indexes} <- Snap.get(cluster, "/_cat/indices", [format: "json"], [], opts) do
      indexes =
        indexes
        |> Enum.map(& &1["index"])
        # Only return indexes inside this namespace
        |> Enum.filter(&Namespace.index_in_namespace?(&1, cluster))
        # Present them without the namespace prefix
        |> Enum.map(&Namespace.strip_namespace(&1, cluster))
        |> Enum.sort()

      {:ok, indexes}
    end
  end

  @doc """
  Lists all the timestamp versioned indexes starting with the prefix.
  """
  @spec list_starting_with(module(), String.t(), Keyword.t()) ::
          {:ok, list(String.t())} | Cluster.error()
  def list_starting_with(cluster, prefix, opts \\ []) do
    with {:ok, indexes} <- Snap.get(cluster, "/_cat/indices", [format: "json"], [], opts) do
      prefix = prefix |> to_string() |> Regex.escape()
      {:ok, regex} = Regex.compile("^#{prefix}-[0-9]+$")

      indexes =
        indexes
        |> Enum.map(& &1["index"])
        # Only return indexes inside this namespace
        |> Enum.filter(&Namespace.index_in_namespace?(&1, cluster))
        # Present them without the namespace prefix
        |> Enum.map(&Namespace.strip_namespace(&1, cluster))
        |> Enum.filter(&Regex.match?(regex, &1))
        |> Enum.sort_by(&sort_index_by_timestamp/1)

      {:ok, indexes}
    end
  end

  @doc """
  Deletes older timestamped indexes.
  """
  @spec cleanup(module(), String.t(), non_neg_integer(), Keyword.t()) ::
          :ok | Cluster.error()
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
