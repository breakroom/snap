defmodule Snap.DocumentTest do
  @moduledoc false
  use Snap.IntegrationCase, async: true

  alias Snap.Document
  alias Snap.Indexes

  @test_index "document"

  setup do
    {:ok, _} = Indexes.create(Snap.Test.Cluster, @test_index, %{})
  end

  describe "get/3" do
    test "it returns a valid document" do
      assert {:ok, _} = Document.create(Snap.Test.Cluster, @test_index, %{foo: "bar"}, 1)
      assert {:ok, doc} = Document.get(Snap.Test.Cluster, @test_index, 1)
      assert %{"_id" => "1", "_source" => %{"foo" => "bar"}} = doc
    end

    test "it fails on an invalid document" do
      assert {:error, %Snap.ResponseError{type: "document_not_found"}} =
               Document.get(Snap.Test.Cluster, @test_index, 1)
    end
  end

  describe "add/3" do
    test "it creates successfully" do
      assert {:ok, %{"result" => "created"}} =
               Document.add(Snap.Test.Cluster, @test_index, %{foo: "bar"})
    end
  end

  describe "index/4" do
    test "it can overwrite an existing document" do
      assert {:ok, _} = Document.index(Snap.Test.Cluster, @test_index, %{foo: "bar"}, 1)
      assert {:ok, _} = Document.index(Snap.Test.Cluster, @test_index, %{foo: "baz"}, 1)
      assert {:ok, doc} = Document.get(Snap.Test.Cluster, @test_index, 1)
      assert %{"_id" => "1", "_source" => %{"foo" => "baz"}} = doc
    end
  end

  describe "delete/3" do
    test "it deletes successfully" do
      assert {:ok, _} = Document.create(Snap.Test.Cluster, @test_index, %{foo: "bar"}, 1)
      assert {:ok, _} = Document.delete(Snap.Test.Cluster, @test_index, 1)

      assert {:error, %Snap.ResponseError{type: "document_not_found"}} =
               Document.get(Snap.Test.Cluster, @test_index, 1)
    end
  end

  describe "update/4" do
    test "it updates successfully" do
      assert {:ok, _} = Document.create(Snap.Test.Cluster, @test_index, %{foo: "bar"}, 1)
      assert {:ok, _} = Document.update(Snap.Test.Cluster, @test_index, %{doc: %{foo: "baz"}}, 1)
      assert {:ok, doc} = Document.get(Snap.Test.Cluster, @test_index, 1)
      assert %{"_id" => "1", "_source" => %{"foo" => "baz"}} = doc
    end
  end
end
