defmodule Snap.IndexesTest do
  @moduledoc false
  use Snap.IntegrationCase, async: true

  alias Snap
  alias Snap.Bulk.Action.Create
  alias Snap.Document
  alias Snap.Indexes
  alias Snap.Search
  alias Snap.Test.Cluster

  @test_index "indexes"

  test "creating an index" do
    assert {:ok, _} = Indexes.create(Cluster, @test_index, %{})
  end

  test "creating and deleting an index" do
    assert {:ok, _} = Indexes.create(Cluster, @test_index, %{})
    assert {:ok, _} = Indexes.delete(Cluster, @test_index)
  end

  test "create an index, load a document and refresh it" do
    assert {:ok, _} = Indexes.create(Cluster, @test_index, %{})
    assert {:ok, _} = Document.index(Cluster, @test_index, %{foo: "bar"}, 1)
    assert :ok = Indexes.refresh(Cluster, @test_index)
    assert {:ok, _} = Document.get(Cluster, @test_index, 1)
  end

  test "create an index, load a document, alias it and fetch back" do
    index = @test_index
    alias = "alias"

    assert {:ok, _} = Indexes.create(Cluster, index, %{})
    assert {:ok, _} = Document.index(Cluster, index, %{foo: "bar"}, 1)
    assert :ok = Indexes.alias(Cluster, index, alias)
    assert {:ok, _} = Document.get(Cluster, alias, 1)
  end

  test "hotswap loading 10,000 documents" do
    result =
      1..10_000
      |> Stream.map(fn i ->
        doc = %{"title" => "Document #{i}"}

        %Create{id: i, doc: doc}
      end)
      |> Indexes.hotswap(Cluster, @test_index, %{}, page_wait: 0, page_size: 1_000)

    assert result == :ok

    {:ok, count} = Search.count(Cluster, @test_index, %{query: %{match_all: %{}}})

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

        %Create{id: i, doc: doc}
      end)
      |> Indexes.hotswap(Cluster, @test_index, %{}, page_wait: 0, page_size: 1_000)

    {:ok, indexes} = Indexes.list_starting_with(Cluster, @test_index)
    assert Enum.count(indexes) == 2
    refute Enum.member?(indexes, "#{@test_index}-1")
    refute Enum.member?(indexes, "#{@test_index}-2")
    assert Enum.member?(indexes, "#{@test_index}-3")
  end
end
