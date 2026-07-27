defmodule Snap.Bulk.ActionsTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Snap.Bulk.Action
  alias Snap.Bulk.Actions

  test "encoding actions" do
    doc = %{"foo" => "bar"}

    actions = [
      %Action.Index{index: "foo", doc: doc, routing: "baz"},
      %Action.Create{index: "foo", doc: doc, require_alias: true},
      %Action.Update{index: "foo", doc: doc, id: 2, routing: "baz"},
      %Action.Delete{index: "foo", id: 1}
    ]

    encoded = Actions.encode(actions) |> IO.chardata_to_string()

    lines =
      encoded
      |> String.split("\n", trim: true)
      |> Enum.map(&Jason.decode!/1)

    assert lines == [
             %{"index" => %{"_index" => "foo", "routing" => "baz"}},
             doc,
             %{"create" => %{"_index" => "foo", "require_alias" => true}},
             doc,
             %{"update" => %{"_index" => "foo", "_id" => 2, "routing" => "baz"}},
             %{"doc" => doc},
             %{"delete" => %{"_index" => "foo", "_id" => 1}}
           ]
  end

  test "encoding an index action with all fields" do
    doc = %{"foo" => "bar"}

    action = %Action.Index{
      index: "foo",
      id: "1",
      doc: doc,
      require_alias: true,
      routing: "baz",
      version: 3,
      version_type: :external,
      if_seq_no: 10,
      if_primary_term: 2,
      pipeline: "my-pipeline"
    }

    assert encode([action]) == [
             %{
               "index" => %{
                 "_index" => "foo",
                 "_id" => "1",
                 "require_alias" => true,
                 "routing" => "baz",
                 "version" => 3,
                 "version_type" => "external",
                 "if_seq_no" => 10,
                 "if_primary_term" => 2,
                 "pipeline" => "my-pipeline"
               }
             },
             doc
           ]
  end

  test "encoding a create action with all fields" do
    doc = %{"foo" => "bar"}

    action = %Action.Create{
      index: "foo",
      id: "1",
      doc: doc,
      require_alias: true,
      routing: "baz",
      version: 3,
      version_type: :external_gte,
      if_seq_no: 10,
      if_primary_term: 2,
      pipeline: "my-pipeline"
    }

    assert encode([action]) == [
             %{
               "create" => %{
                 "_index" => "foo",
                 "_id" => "1",
                 "require_alias" => true,
                 "routing" => "baz",
                 "version" => 3,
                 "version_type" => "external_gte",
                 "if_seq_no" => 10,
                 "if_primary_term" => 2,
                 "pipeline" => "my-pipeline"
               }
             },
             doc
           ]
  end

  test "encoding a delete action with all fields" do
    action = %Action.Delete{
      index: "foo",
      id: "1",
      require_alias: true,
      routing: "baz",
      version: 3,
      version_type: "internal",
      if_seq_no: 10,
      if_primary_term: 2
    }

    assert encode([action]) == [
             %{
               "delete" => %{
                 "_index" => "foo",
                 "_id" => "1",
                 "require_alias" => true,
                 "routing" => "baz",
                 "version" => 3,
                 "version_type" => "internal",
                 "if_seq_no" => 10,
                 "if_primary_term" => 2
               }
             }
           ]
  end

  test "encoding an update action with all fields" do
    doc = %{"foo" => "bar"}
    upsert = %{"foo" => "baz"}
    script = %{"source" => "ctx._source.foo = 'bar'"}

    action = %Action.Update{
      index: "foo",
      id: "1",
      require_alias: true,
      routing: "baz",
      if_seq_no: 10,
      if_primary_term: 2,
      retry_on_conflict: 3,
      pipeline: "my-pipeline",
      source: ["foo"],
      doc: doc,
      doc_as_upsert: false,
      script: script,
      upsert: upsert,
      scripted_upsert: true,
      detect_noop: false
    }

    assert encode([action]) == [
             %{
               "update" => %{
                 "_index" => "foo",
                 "_id" => "1",
                 "require_alias" => true,
                 "routing" => "baz",
                 "if_seq_no" => 10,
                 "if_primary_term" => 2,
                 "retry_on_conflict" => 3,
                 "pipeline" => "my-pipeline",
                 "_source" => ["foo"]
               }
             },
             %{
               "doc" => doc,
               "doc_as_upsert" => false,
               "script" => script,
               "upsert" => upsert,
               "scripted_upsert" => true,
               "detect_noop" => false
             }
           ]
  end

  test "encoding an update action with only a script" do
    script = %{"source" => "ctx._source.counter += 1"}

    assert encode([%Action.Update{id: "1", script: script}]) == [
             %{"update" => %{"_id" => "1"}},
             %{"script" => script}
           ]
  end

  defp encode(actions) do
    actions
    |> Actions.encode()
    |> IO.chardata_to_string()
    |> String.split("\n", trim: true)
    |> Enum.map(&Jason.decode!/1)
  end
end
