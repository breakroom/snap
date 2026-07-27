defmodule Snap.BulkTest do
  @moduledoc false
  use Snap.IntegrationCase, async: true

  alias Snap
  alias Snap.Bulk
  alias Snap.Bulk.Action
  alias Snap.Test.Cluster

  @test_index "bulk"

  describe "perform/4" do
    test "running actions in 2 chunks with no errors" do
      {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

      doc = %{foo: "bar"}

      actions = [
        %Action.Index{doc: doc, id: 1},
        %Action.Index{doc: doc, id: 2},
        %Action.Delete{id: 1},
        %Action.Delete{id: 2}
      ]

      result =
        actions
        |> Bulk.perform(Cluster, @test_index, page_size: 2, page_wait: 10)

      assert result == :ok
    end

    test "running actions in 2 chunks with errors in both chunks" do
      {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

      doc = %{foo: "bar"}

      actions = [
        %Action.Index{doc: doc, id: 1},
        %Action.Update{doc: doc, id: 2},
        %Action.Update{doc: doc, id: 3},
        %Action.Update{doc: doc, id: 4}
      ]

      {:error, %Snap.BulkError{errors: errors}} =
        actions
        |> Bulk.perform(Cluster, @test_index, page_size: 2, page_wait: 10)

      assert Enum.count(errors) == 3

      error = Enum.at(errors, 0)

      assert error.status == 404
    end

    test "running actions in 2 chunks with max_errors count that gets exceeded in the first chunk" do
      {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

      doc = %{foo: "bar"}

      actions = [
        %Action.Update{id: 1, doc: doc},
        %Action.Update{id: 2, doc: doc},
        %Action.Update{id: 3, doc: doc},
        %Action.Update{id: 4, doc: doc}
      ]

      {:error, %Snap.BulkError{errors: errors}} =
        actions
        |> Bulk.perform(Cluster, @test_index, page_size: 2, page_wait: 10, max_errors: 2)

      assert Enum.count(errors) == 4
    end

    test "running actions in 3 chunks with max_errors count that gets exceeded in the second chunk" do
      {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

      doc = %{foo: "bar"}

      actions = [
        %Action.Update{id: 1, doc: doc},
        %Action.Update{id: 2, doc: doc},
        %Action.Update{id: 3, doc: doc},
        %Action.Update{id: 4, doc: doc},
        %Action.Update{id: 5, doc: doc},
        %Action.Update{id: 6, doc: doc}
      ]

      {:error, %Snap.BulkError{errors: errors}} =
        actions
        |> Bulk.perform(Cluster, @test_index, page_size: 2, page_wait: 10, max_errors: 3)

      assert Enum.count(errors) == 4
    end

    test "running actions in 2 chunks with a 0 max_errors count that never gets exceeded" do
      {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

      doc = %{foo: "bar"}

      actions = [
        %Action.Index{id: 1, doc: doc},
        %Action.Index{id: 2, doc: doc},
        %Action.Index{id: 3, doc: doc},
        %Action.Index{id: 4, doc: doc},
        %Action.Index{id: 5, doc: doc},
        %Action.Index{id: 6, doc: doc}
      ]

      assert :ok ==
               actions
               |> Bulk.perform(Cluster, @test_index, page_size: 2, page_wait: 10, max_errors: 0)
    end

    test "upserting with doc_as_upsert" do
      {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

      actions = [
        %Action.Update{id: 1, doc: %{foo: "bar"}, doc_as_upsert: true}
      ]

      assert :ok == Bulk.perform(actions, Cluster, @test_index)

      assert {:ok, %{"_source" => %{"foo" => "bar"}}} =
               Snap.Document.get(Cluster, @test_index, 1)
    end

    test "upserting with an explicit upsert document" do
      {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

      actions = [
        %Action.Update{id: 1, doc: %{foo: "bar"}, upsert: %{foo: "baz", count: 1}}
      ]

      assert :ok == Bulk.perform(actions, Cluster, @test_index)

      assert {:ok, %{"_source" => %{"foo" => "baz", "count" => 1}}} =
               Snap.Document.get(Cluster, @test_index, 1)
    end

    test "updating with a script and no doc" do
      {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

      actions = [
        %Action.Index{id: 1, doc: %{count: 1}},
        %Action.Update{
          id: 1,
          script: %{source: "ctx._source.count += params.by", params: %{by: 4}},
          retry_on_conflict: 3
        }
      ]

      assert :ok == Bulk.perform(actions, Cluster, @test_index)

      assert {:ok, %{"_source" => %{"count" => 5}}} = Snap.Document.get(Cluster, @test_index, 1)
    end

    test "updating with a scripted upsert" do
      {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

      actions = [
        %Action.Update{
          id: 1,
          script: %{source: "ctx._source.count = params.count", params: %{count: 7}},
          upsert: %{},
          scripted_upsert: true
        }
      ]

      assert :ok == Bulk.perform(actions, Cluster, @test_index)

      assert {:ok, %{"_source" => %{"count" => 7}}} = Snap.Document.get(Cluster, @test_index, 1)
    end

    test "indexing with an external version" do
      {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

      actions = [
        %Action.Index{id: 1, doc: %{foo: "bar"}, version: 5, version_type: :external}
      ]

      assert :ok == Bulk.perform(actions, Cluster, @test_index)

      assert {:ok, %{"_version" => 5}} = Snap.Document.get(Cluster, @test_index, 1)

      stale = [
        %Action.Index{id: 1, doc: %{foo: "baz"}, version: 4, version_type: :external}
      ]

      assert {:error, %Snap.BulkError{errors: [error]}} =
               Bulk.perform(stale, Cluster, @test_index)

      assert error.type == "version_conflict_engine_exception"
    end

    test "indexing with if_seq_no and if_primary_term" do
      {:ok, _} = Snap.Indexes.create(Cluster, @test_index, %{})

      assert :ok == Bulk.perform([%Action.Index{id: 1, doc: %{foo: "bar"}}], Cluster, @test_index)

      {:ok, %{"_seq_no" => seq_no, "_primary_term" => primary_term}} =
        Snap.Document.get(Cluster, @test_index, 1)

      actions = [
        %Action.Index{
          id: 1,
          doc: %{foo: "baz"},
          if_seq_no: seq_no,
          if_primary_term: primary_term
        }
      ]

      assert :ok == Bulk.perform(actions, Cluster, @test_index)

      stale = [
        %Action.Index{
          id: 1,
          doc: %{foo: "qux"},
          if_seq_no: seq_no,
          if_primary_term: primary_term
        }
      ]

      assert {:error, %Snap.BulkError{errors: [error]}} =
               Bulk.perform(stale, Cluster, @test_index)

      assert error.type == "version_conflict_engine_exception"
    end
  end
end
