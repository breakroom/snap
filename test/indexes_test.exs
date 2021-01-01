defmodule Snap.IndexesTest do
  use Snap.IntegrationCase

  alias Snap
  alias Snap.Bulk.Action.Create
  alias Snap.Indexes
  alias Snap.Test.Cluster

  test "creating an index" do
    assert {:ok, _} = Indexes.create(Cluster, @test_index, %{})
  end

  test "creating and deleting an index" do
    assert {:ok, _} = Indexes.create(Cluster, @test_index, %{})
    assert {:ok, _} = Indexes.delete(Cluster, @test_index)
  end

  test "create an index, load a document and refresh it" do
    assert {:ok, _} = Indexes.create(Cluster, @test_index, %{})
    assert {:ok, _} = Snap.put(Cluster, "/#{@test_index}/_doc/1", %{foo: "bar"})
    assert :ok = Indexes.refresh(Cluster, @test_index)
    assert {:ok, _} = Snap.get(Cluster, "/#{@test_index}/_doc/1")
  end

  test "create an index, load a document, alias it and fetch back" do
    index = "#{@test_index}-123"
    alias = @test_index

    assert {:ok, _} = Indexes.create(Cluster, index, %{})
    assert {:ok, _} = Snap.put(Cluster, "/#{index}/_doc/1", %{foo: "bar"})
    assert :ok = Indexes.alias(Cluster, index, alias)
    assert {:ok, _} = Snap.get(Cluster, "/#{alias}/_doc/1")
  end

  test "hotswap loading 10,000 documents" do
    result =
      1..10_000
      |> Stream.map(fn i ->
        doc = %{"title" => "Document #{i}"}

        %Create{_id: i, doc: doc}
      end)
      |> Indexes.hotswap(Cluster, @test_index, %{}, page_wait: 0, page_size: 1_000)

    assert result == :ok

    {:ok, %{"count" => count}} = Snap.get(Cluster, "/#{@test_index}/_count")
    assert count == 10_000
  end
end
