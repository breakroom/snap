defmodule Snap.Cluster.NamespaceTest do
  use ExUnit.Case, async: false

  alias Snap.Cluster.Namespace

  defmodule NoNamespaceCluster do
    @moduledoc false
    use Snap.Cluster, otp_app: :snap

    def init(config) do
      config =
        config
        |> Keyword.delete(:index_namespace)
        |> Keyword.put(:url, "http://foo")

      {:ok, config}
    end
  end

  defmodule NamespaceCluster do
    @moduledoc false
    use Snap.Cluster, otp_app: :snap

    def init(config) do
      config =
        config
        |> Keyword.put(:index_namespace, "cluster")
        |> Keyword.put(:url, "http://foo")

      {:ok, config}
    end
  end

  setup_all do
    {:ok, namespace_pid} = NamespaceCluster.start_link()
    {:ok, no_namespace_pid} = NoNamespaceCluster.start_link()

    %{namespace_cluster_pid: namespace_pid, no_namespace_cluster_pid: no_namespace_pid}
  end

  describe "add_namespace_to_index/2" do
    test "without a cluster index_namespace" do
      assert nil == Namespace.index_namespace(NoNamespaceCluster)
      assert "foo" == Namespace.add_namespace_to_index(:foo, NoNamespaceCluster)
    end

    test "with a cluster index_namespace" do
      assert "cluster" == Namespace.index_namespace(NamespaceCluster)
      assert "cluster-foo" == Namespace.add_namespace_to_index(:foo, NamespaceCluster)
    end
  end

  describe "set_process_namespace/3 and clear_process_namespace/2" do
    test "without a cluster index_namespace" do
      Namespace.set_process_namespace(NoNamespaceCluster, "process")
      assert "process-index" == Namespace.add_namespace_to_index("index", NoNamespaceCluster)

      Namespace.clear_process_namespace(NoNamespaceCluster, self())
      assert "index" == Namespace.add_namespace_to_index("index", NoNamespaceCluster)
    end

    test "with a cluster index_namespace" do
      Namespace.set_process_namespace(NamespaceCluster, "process")

      assert "cluster-process-index" ==
               Namespace.add_namespace_to_index("index", NamespaceCluster)

      task =
        Task.async(fn ->
          Namespace.add_namespace_to_index("index", NamespaceCluster)
        end)

      assert "cluster-process-index" == Task.await(task)

      Namespace.clear_process_namespace(NamespaceCluster, self())
      assert "cluster-index" == Namespace.add_namespace_to_index("index", NamespaceCluster)
    end
  end

  describe "index_in_namespace?/2" do
    test "with an index in the cluster namespace" do
      assert true == Namespace.index_in_namespace?("cluster-baz", NamespaceCluster)
    end

    test "with an index not in the cluster namespace" do
      assert false == Namespace.index_in_namespace?("different-baz", NamespaceCluster)
    end

    test "with an index and no cluster index_namespace" do
      assert true == Namespace.index_in_namespace?("foo-baz", NoNamespaceCluster)
    end
  end

  describe "strip_namespace/2" do
    test "it strips the cluster namespace" do
      assert "foo" == Namespace.strip_namespace("cluster-foo", NamespaceCluster)
    end

    test "it doesn't strip something that isn't the cluster namespace" do
      assert "notcluster-foo" == Namespace.strip_namespace("notcluster-foo", NamespaceCluster)
    end

    test "it preserves the index without a cluster namespace" do
      assert "cluster-foo" == Namespace.strip_namespace("cluster-foo", NoNamespaceCluster)
    end
  end
end
