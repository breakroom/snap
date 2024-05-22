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
end
