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
    assert {:ok, _} = Cluster.put("/#{@test_index}/_doc/1", %{foo: "bar"})
    assert :ok = Indexes.refresh(Cluster, @test_index)
    assert {:ok, _} = Cluster.get("/#{@test_index}/_doc/1")
  end

  test "create an index, load a document, alias it and fetch back" do
    index = "#{@test_index}-123"
    alias = @test_index

    assert {:ok, _} = Indexes.create(Cluster, index, %{})
    assert {:ok, _} = Cluster.put("/#{index}/_doc/1", %{foo: "bar"})
    assert :ok = Indexes.alias(Cluster, index, alias)
    assert {:ok, _} = Cluster.get("/#{alias}/_doc/1")
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

    {:ok, %{"count" => count}} = Cluster.get("/#{@test_index}/_count")
    assert count == 10_000
  end

  test "hotswap drops older indexes" do
    {:ok, _} = Indexes.create(Cluster, "#{@test_index}-1", %{})
    {:ok, _} = Indexes.create(Cluster, "#{@test_index}-2", %{})
    {:ok, _} = Indexes.create(Cluster, "#{@test_index}-3", %{})

    {:ok, indexes} = Indexes.list_starting_with(Cluster, @test_index)
    assert Enum.count(indexes) == 3

    :ok =
      1..10
      |> Stream.map(fn i ->
        doc = %{"title" => "Document #{i}"}

        %Create{_id: i, doc: doc}
      end)
      |> Indexes.hotswap(Cluster, @test_index, %{}, page_wait: 0, page_size: 1_000)

    {:ok, indexes} = Indexes.list_starting_with(Cluster, @test_index)
    assert Enum.count(indexes) == 2
    refute Enum.member?(indexes, "#{@test_index}-1")
    refute Enum.member?(indexes, "#{@test_index}-2")
    assert Enum.member?(indexes, "#{@test_index}-3")
  end
end
