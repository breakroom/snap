defmodule Snap.Test do
  @moduledoc """
  Helpers around testing with `Snap`.

  Unlike SQL databases, ElasticSearch/OpenSearch does not provide transaction
  isolation, which is how `Ecto.Adapters.SQL.Sandbox` isolates test
  processes, allowing multiple tests to run asynchronously.

  `Snap` uses a different approach. It can set an index namespace for a running
  process, which scopes all the convenience API operations to that index
  namespace, so they don't collide with each other.

  This allows tests to run asynchronously, improving the performance.

  To set this up, you'll want to use [tags](https://hexdocs.pm/ex_unit/1.12.3/ExUnit.Case.html#module-tags) in `ExUnit`

  In your test you'll do something similar to:

  ```
  setup context do
    if context[:snap] do
      namespace = Snap.Test.generate_namespace_for_pid(self())
      Snap.Cluster.Namespace.set_process_namespace(Cluster, namespace)
      Snap.Test.drop_indexes(Cluster)

      on_exit(fn ->
        Snap.Cluster.Namespace.set_process_namespace(Cluster, namespace)
        Snap.Test.drop_indexes(Cluster)
      end)
    end
  end

  @tag :snap
  test "test something with snap" do
    ...
  end
  ```

  This generate a unique namespace for the running process and assigns to the
  cluster. It clears the indexes to make sure the test is starting from scratch.

  It setups up a `on_exit/1` callback, which runs in a separate process after
  the test has completed. The namespace is passed through from the test's
  process, so it can teardown all the indexes created by the test.
  """

  alias Snap.Cluster.Namespace

  @doc """
  Generates a `String` namespace for the provided pid, by hashing it.
  """
  def generate_namespace_for_pid(pid) when is_pid(pid) do
    pid_to_string(pid)
  end

  @doc """
  Drops all the indexes on the cluster. Beware!
  """
  def drop_indexes(cluster) do
    {:ok, indexes} = Snap.Indexes.list(cluster)

    indexes
    |> Enum.each(fn i ->
      {:ok, _} = Snap.Indexes.delete(cluster, i)
    end)
  end

  @doc """
  Takes the process namespace from one process and set it on another. Useful if
  your tests start multiple processes and they all need to have the same view of
  your cluster.
  """
  def propogate_namespace(cluster, from_pid, to_pid) when is_pid(from_pid) and is_pid(to_pid) do
    case Namespace.get_process_namespace(cluster, from_pid) do
      nil -> raise("No namespace set for process #{inspect(from_pid)}")
      namespace -> Namespace.set_process_namespace(cluster, to_pid, namespace)
    end
  end

  defp pid_to_string(pid) do
    pid
    |> :erlang.phash2()
    |> to_string()
  end
end
