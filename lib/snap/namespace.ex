defmodule Snap.Cluster.Namespace do
  @moduledoc """
  Manages the namespacing of a cluster, so a cluster can be scoped to only
  operate on indexes with a specific prefix.

  This is useful for a few purposes:

  - Running multiple instances of `Snap`, across completely different
    applications, against a single cluster. You might not want do this in
    production, but it's useful to only run one ElasticSearch/OpenSearch server
    locally when working on multiple applications.

  - Running multiple environments of the same application. You don't want your
    tests to blow away all your development data each time they run.

  - Running tests in parallel, so each test process cannot see or act upon
    indexes that another test is operating on. This gives you the benefits of
    `Ecto` style sandboxing, meaning your tests can run with `async: true` even
    though ElasticSearch/OpenSearch doesn't support isolated transactions.

  All of the convenience modules respect namespacing:

  * `Snap.Bulk`
  * `Snap.Document`
  * `Snap.Indexes`
  * `Snap.Multi`
  * `Snap.Search`

  The low level HTTP API on `Snap` does not.

  There are two types of namespace:

  ## Config namespace

  You can namespace the entire `Snap.Cluster` in the config. This is used to
  achieve isolation at a per application and environment level.

  For example, to isolate your development and test environments, set
  `index_namespace: "dev"` in your dev config, and `index_namespace: "test"` in
  your test config.

  You might even want to isolate multiple applications on a per environment
  basis, with `index_namespace: "app1-dev"`, for example.

  ## Process namespace

  The process namespace is used to achieve isolation between parallel running
  tests. It's not likely you'll want to use this in other situations.

  For more information, see `Snap.Test`.
  """

  @separator "-"
  @index_separator ","

  @doc """
  Sets an index namespace for the currently running process.
  """
  def set_process_namespace(cluster, namespace) when is_binary(namespace) do
    Process.put({cluster, :namespace}, namespace)
  end

  @doc """
  Returns the previously set process namespace, if any.

  Will walk up to an ancestor process if the current process doesn't have a
  namespace defined. This makes it easy to set a namespace in a test process,
  and ensuring that any child processes within the test also respect the
  namespace (e.g. LiveViews).
  """
  def get_process_namespace(cluster) do
    ProcessTree.get({cluster, :namespace})
  end

  @doc """
  Clears the previously set process namespace, if any.
  """
  def clear_process_namespace(cluster) do
    Process.put({cluster, :namespace}, nil)
  end

  @doc """
  Given an index, adds the namespace to the supplied index for the
  `Snap.Cluster` in the currently running process.

  The index can be:

  - a string or atom naming a single index
  - a comma-separated string of indexes (e.g. `"foo,bar"`)
  - a list of strings or atoms (e.g. `["foo", "bar"]`)

  Multi-index inputs are returned as a comma-separated string, with each
  index individually namespaced.
  """
  def add_namespace_to_index(indexes, cluster) when is_list(indexes) do
    prefix = namespace_prefix(cluster)
    Enum.map_join(indexes, @index_separator, &apply_prefix(prefix, &1))
  end

  def add_namespace_to_index(index, cluster) when is_binary(index) do
    String.split(index, @index_separator)
    |> Enum.map(&String.trim/1)
    |> add_namespace_to_index(cluster)
  end

  def add_namespace_to_index(index, cluster) do
    apply_prefix(namespace_prefix(cluster), index)
  end

  defp namespace_prefix(cluster) do
    [config_namespace(cluster), get_process_namespace(cluster)]
    |> Enum.reject(&is_nil/1)
  end

  defp apply_prefix(prefix, index) do
    merge_elements(prefix ++ [to_string(index)])
  end

  @doc """
  Given an index, returns the index namespace for the `Snap.Cluster` in the
  currently running process.
  """
  def index_namespace(cluster) do
    [config_namespace(cluster), get_process_namespace(cluster)]
    |> Enum.reject(&is_nil/1)
    |> merge_elements()
  end

  @doc """
  Returns a boolean indicating whether the namespaced index is inside the currently
  defined namespace.
  """
  def index_in_namespace?(namespaced_index, cluster) do
    case index_namespace(cluster) do
      nil -> true
      namespace -> String.starts_with?(namespaced_index, "#{namespace}#{@separator}")
    end
  end

  @doc """
  Remove the namespace prefix from a namespaced index, returning the remainder.
  """
  def strip_namespace(namespaced_index, cluster) do
    case index_namespace(cluster) do
      nil -> namespaced_index
      namespace -> String.replace_leading(namespaced_index, "#{namespace}#{@separator}", "")
    end
  end

  defp config_namespace(cluster) do
    config = cluster.config()
    Keyword.get(config, :index_namespace)
  end

  defp merge_elements([]), do: nil
  defp merge_elements(list), do: Enum.join(list, @separator)
end
