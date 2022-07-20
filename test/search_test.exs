defmodule Snap.SearchTest do
  use Snap.IntegrationCase

  alias Snap.Bulk.Action
  alias Snap.Search
  alias Snap.Test.Cluster

  test "simple search response" do
    {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

    1..5
    |> Enum.map(fn i ->
      doc = %{"title" => "Document #{i}"}

      %Action.Index{_id: i, doc: doc}
    end)
    |> Snap.Bulk.perform(Cluster, @test_index, refresh: :wait_for)

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
    |> Snap.Bulk.perform(Cluster, @test_index, refresh: :wait_for)

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
end
