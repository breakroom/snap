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

      %Action.Index{id: i, doc: doc}
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

      %Action.Index{id: i, doc: doc}
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
             suggest: %{
               "title" => [
                 %Snap.Suggest{
                   text: "doument",
                   options: [%Snap.Suggest.Option{freq: 5, text: "document", score: score}]
                 }
               ]
             }
           } = search_response

    assert is_float(score)
  end

  test "search with an autocomplete response" do
    {:ok, _} =
      Snap.Indexes.create(Cluster, @test_index, %{
        mappings: %{
          properties: %{
            name: %{
              type: "completion"
            }
          }
        }
      })

    [
      %Action.Index{id: 1, doc: %{name: "Cat"}},
      %Action.Index{id: 2, doc: %{name: "Caracal"}},
      %Action.Index{id: 3, doc: %{name: "Dog"}}
    ]
    |> Snap.Bulk.perform(Cluster, @test_index, refresh: true)

    query = %{
      suggest: %{
        autocomplete: %{
          prefix: "ca",
          completion: %{
            field: "name"
          }
        }
      }
    }

    {:ok, search_response} = Search.search(Cluster, @test_index, query)

    assert %Snap.SearchResponse{
             suggest: %{
               "autocomplete" => [
                 %Snap.Suggest{
                   text: "ca",
                   options: [
                     %Snap.Suggest.Option{
                       id: "2",
                       text: "Caracal",
                       score: caracal_score,
                       index: index,
                       source: %{"name" => "Caracal"}
                     },
                     %Snap.Suggest.Option{
                       id: "1",
                       text: "Cat",
                       score: cat_score,
                       index: index,
                       source: %{"name" => "Cat"}
                     }
                   ]
                 }
               ]
             }
           } = search_response

    assert is_float(caracal_score)
    assert is_float(cat_score)
    assert is_binary(index)
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
