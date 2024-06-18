defmodule Snap.IndexesTest do
  @moduledoc false
  use Snap.IntegrationCase, async: true

  alias Snap
  alias Snap.Bulk.Action.Create
  alias Snap.Cluster.Namespace
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

  test "update an indices mapping" do
    mapping = %{"properties" => %{"test" => %{"type" => "text"}}}

    assert {:ok, _} = Indexes.create(Cluster, @test_index, %{})
    assert {:ok, _} = Indexes.update_mapping(Cluster, @test_index, mapping)
    assert {:ok, result} = Indexes.get_mapping(Cluster, @test_index)
    index = Namespace.add_namespace_to_index(@test_index, Cluster)
    assert result[index]["mappings"] == mapping
  end

  test "get an indices settings" do
    index = Namespace.add_namespace_to_index(@test_index, Cluster)

    assert {:ok, _} = Indexes.create(Cluster, @test_index, %{})
    assert {:ok, result} = Indexes.get_settings(Cluster, @test_index)
    assert %{^index => %{"settings" => %{"index" => _}}} = result
  end

  test "get an indices setting" do
    index = Namespace.add_namespace_to_index(@test_index, Cluster)

    assert {:ok, _} = Indexes.create(Cluster, @test_index, %{})
    assert {:ok, result} = Indexes.get_setting(Cluster, @test_index, "index.number_of_shards")

    assert %{
             ^index => %{
               "settings" => %{
                 "index" => %{
                   "number_of_shards" => "1"
                 }
               }
             }
           } = result
  end

  test "update an indices setting" do
    index = Namespace.add_namespace_to_index(@test_index, Cluster)

    assert {:ok, _} = Indexes.create(Cluster, @test_index, %{})

    settings = %{
      "index" => %{
        "number_of_replicas" => "0"
      }
    }

    assert {:ok, _} = Indexes.update_settings(Cluster, @test_index, settings)
    assert {:ok, result} = Indexes.get_setting(Cluster, @test_index, "index.number_of_replicas")

    assert %{
             ^index => %{
               "settings" => %{
                 "index" => %{
                   "number_of_replicas" => "0"
                 }
               }
             }
           } = result
  end

  test "get an indices shard store" do
    index = Namespace.add_namespace_to_index(@test_index, Cluster)

    assert {:ok, _} = Indexes.create(Cluster, @test_index, %{})
    assert {:ok, result} = Indexes.get_shard_stores(Cluster, @test_index)

    assert %{
             "indices" => %{
               ^index => %{
                 "shards" => _
               }
             }
           } = result
  end

  test "get an indices stats" do
    index = Namespace.add_namespace_to_index(@test_index, Cluster)

    assert {:ok, _} = Indexes.create(Cluster, @test_index, %{})
    assert {:ok, result} = Indexes.get_stats(Cluster, @test_index)

    assert %{
             "indices" => %{
               ^index => _
             }
           } = result
  end

  test "get an indices stat" do
    index = Namespace.add_namespace_to_index(@test_index, Cluster)

    assert {:ok, _} = Indexes.create(Cluster, @test_index, %{})
    assert {:ok, result} = Indexes.get_stat(Cluster, @test_index, "indexing")

    assert %{
             "indices" => %{
               ^index => _
             }
           } = result

    assert {:ok, result} = Indexes.get_stat(Cluster, @test_index, "indexing,get")

    assert %{
             "indices" => %{
               ^index => _
             }
           } = result
  end

  test "closing and opening index" do
    assert {:ok, _} = Indexes.create(Cluster, @test_index, %{})
    assert {:ok, _} = Indexes.close(Cluster, @test_index)
    assert {:ok, _} = Indexes.open(Cluster, @test_index)
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
