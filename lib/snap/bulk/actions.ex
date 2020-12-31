defmodule Snap.Bulk.Actions do
  alias Snap.Bulk.Action.{Create, Index, Update, Delete}

  @doc """
  Encodes a list of bulk action structs into line separated JSON for feeding to the
  /_bulk endpoint.
  """
  def encode(actions) do
    encode_actions([], actions)
  end

  defp encode_actions(iolist, []) do
    iolist
  end

  defp encode_actions(iolist, [head | tail]) do
    updated_iolist = [iolist, encode_action(head)]
    encode_actions(updated_iolist, tail)
  end

  defp encode_action(%type{} = action) when type in [Create, Index] do
    doc = action.doc

    doc_json =
      doc
      |> Jason.encode!()

    action_json = encode_action_command(action)

    [action_json, "\n", doc_json, "\n"]
  end

  defp encode_action(%Delete{} = action) do
    action_json = encode_action_command(action)

    [action_json, "\n"]
  end

  defp encode_action(%Update{} = action) do
    doc = action.doc

    doc_json =
      %{doc: doc}
      |> Jason.encode!()

    action_json = encode_action_command(action)

    [action_json, "\n", doc_json, "\n"]
  end

  defp encode_action_command(action) do
    key =
      case action do
        %Create{} -> "create"
        %Update{} -> "update"
        %Delete{} -> "delete"
        %Index{} -> "index"
      end

    body =
      action
      |> Map.from_struct()
      |> Map.delete(:doc)
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Map.new()

    %{key => body}
    |> Jason.encode!()
  end
end
