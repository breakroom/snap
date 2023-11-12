defmodule Snap.SearchTest do
  @moduledoc false
  use Snap.IntegrationCase, async: true

  alias Snap.Bulk.Action
  alias Snap.Search
  alias Snap.Test.Cluster

  @test_index "search"

  test "simple search response" do
    {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

    1..5
    |> Enum.map(fn i ->
      doc = %{"title" => "Document #{i}"}

      %Action.Index{_id: i, doc: doc}
    end)
    |> Snap.Bulk.perform(Cluster, @test_index, refresh: true)

    query = %{"query" => %{"match_all" => %{}}, "sort" => ["_doc"]}

    {:ok, search_response} = Search.search(Cluster, @test_index, query)
    assert Enum.count(search_response) == 5

    first_hit = Enum.at(search_response, 0)
    assert first_hit.id == "1"
    assert first_hit.source["title"] == "Document 1"
  end

  test "search with suggestion response" do
    {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

    1..5
    |> Enum.map(fn i ->
      doc = %{"title" => "Document #{i}"}

      %Action.Index{_id: i, doc: doc}
    end)
    |> Snap.Bulk.perform(Cluster, @test_index, refresh: true)

    query = %{
      "query" => %{"match_all" => %{}},
      "sort" => ["_doc"],
      "suggest" => %{"title" => %{"text" => "Doument", "term" => %{"field" => "title"}}}
    }

    {:ok, search_response} = Search.search(Cluster, @test_index, query)
    assert Enum.count(search_response) == 5

    first_hit = Enum.at(search_response, 0)
    assert first_hit.id == "1"
    assert first_hit.source["title"] == "Document 1"

    assert %Snap.SearchResponse{
             suggest: %{"title" => [%{text: "doument", options: [%{text: "document"}]}]}
           } = search_response
  end

  test "count/2 without a query" do
    {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})
    {:ok, _} = Snap.Document.add(Cluster, @test_index, %{foo: "bar"})
    {:ok, _} = Snap.Document.add(Cluster, @test_index, %{foo: "baz"})

    assert :ok = Snap.Indexes.refresh(Cluster, @test_index)

    assert {:ok, 2} = Snap.Search.count(Cluster, @test_index)
  end

  test "count/2 with a query" do
    {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})
    {:ok, _} = Snap.Document.add(Cluster, @test_index, %{foo: "bar"})
    {:ok, _} = Snap.Document.add(Cluster, @test_index, %{foo: "baz"})

    assert :ok = Snap.Indexes.refresh(Cluster, @test_index)

    assert {:ok, 1} = Snap.Search.count(Cluster, @test_index, %{query: %{term: %{foo: "bar"}}})
  end
end
