defmodule Snap.Cluster.Namespace do
  @moduledoc """
  Manages the namespacing of a cluster, so a cluster can be scoped to only
  operate on indexes with a specific prefix.

  This is useful for a few purposes:

  - Running multiple instances of `Snap`, across completely different
    applications, against a single cluster. You might not want do this in
    production, but it's useful to only run one copy of ElasticSearch/OpenSearch
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
  achive isolation at a per application and environment level.

  For example, to isolate your development and test environments, set
  `index_namespace: "dev"` in your dev config, and `index_namespace: "test"` in
  your test config.

  You might even want to isolate multiple applications on a per environment
  basis, with `index_namespace: "app1-dev"`, for example.

  ## Process namespace

  The process namespace is used to achive isolation between parallel running
  tests. It's not likely you'll want to use this in other situations.

  For more information, see `Snap.Test`.
  """
  use GenServer

  alias Snap.Cluster.Supervisor

  @doc false
  def start_link(name) do
    GenServer.start_link(__MODULE__, [], name: name)
  end

  @doc false
  def init([]) do
    {:ok, %{}}
  end

  @doc """
  Set the index namespace of the provided `pid`. Subsequent operations through
  convenience APIs are performed on namespaced indexes.
  """
  def set_process_namespace(cluster, pid, namespace) when is_pid(pid) and is_binary(namespace) do
    GenServer.call(Supervisor.namespace_pid(cluster), {:set, pid, namespace})
  end

  @doc """
  Same as `set_process_namespace/3`, but for the running process.
  """
  def set_process_namespace(cluster, namespace) when is_binary(namespace) do
    set_process_namespace(cluster, self(), namespace)
  end

  @doc """
  Returns the previously set process namespace, if any.
  """
  def get_process_namespace(cluster, pid) when is_pid(pid) do
    GenServer.call(Supervisor.namespace_pid(cluster), {:get, pid})
  end

  @doc """
  Clears the previously set process namespace, if any.
  """
  def clear_process_namespace(cluster, pid) when is_pid(pid) do
    GenServer.call(Supervisor.namespace_pid(cluster), {:clear, pid})
  end

  @doc """
  Given an index, adds the namespace to the supplied index for the
  `Snap.Cluster` in the currently running process.
  """
  def add_namespace_to_index(index, cluster) do
    [config_namespace(cluster), get_process_namespace(cluster, self()), index]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("-")
  end

  @doc """
  Given an index, returns the index namespace for the `Snap.Cluster` in the
  currently running process.
  """
  def index_namespace(cluster) do
    [config_namespace(cluster), get_process_namespace(cluster, self())]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("-")
  end

  @doc false
  def handle_call({:set, pid, namespace}, _from, state) do
    Process.monitor(pid)
    state = Map.put(state, pid, namespace)

    {:reply, :ok, state}
  end

  @doc false
  def handle_call({:clear, pid}, _from, state) do
    state = Map.delete(state, pid)

    {:reply, :ok, state}
  end

  @doc false
  def handle_call({:get, pid}, _from, state) do
    namespace = Map.get(state, pid)

    {:reply, namespace, state}
  end

  @doc false
  # We use this to clear out the namespace for the process when the process
  # dies, so we don't keep filling up our table.
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    state = Map.delete(state, pid)

    {:noreply, state}
  end

  defp config_namespace(cluster) do
    config = cluster.config()
    Keyword.get(config, :index_namespace)
  end
end
