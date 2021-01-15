defmodule Snap.ResponseError do
  @moduledoc """
  Represents an Elasticsearch exception raised while executing a query.
  """

  @keys [
    :status,
    :line,
    :col,
    :message,
    :type,
    :raw
  ]

  @enforce_keys @keys
  defexception @keys

  @type t :: %__MODULE__{
          status: integer() | nil,
          line: integer() | nil,
          col: integer() | nil,
          message: String.t() | nil,
          type: String.t() | nil,
          raw: map() | nil
        }

  def exception_from_response(response) do
    attrs = build(response)
    struct(__MODULE__, attrs)
  end

  def message(exception) do
    type = if exception.type, do: "(#{exception.type})"
    msg = if exception.message, do: exception.message

    [type, msg]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  defp build(%{"error" => error} = response) when is_map(error) do
    [
      status: response["status"],
      line: get_in(response, ["error", "line"]),
      col: get_in(response, ["error", "col"]),
      message: get_in(response, ["error", "reason"]),
      type: type(response),
      raw: response
    ]
  end

  defp build(%{"result" => type}) do
    [
      status: nil,
      line: nil,
      col: nil,
      message: nil,
      type: type
    ]
  end

  defp build(%{"found" => false}) do
    [
      status: nil,
      line: nil,
      col: nil,
      message: nil,
      type: "document_not_found"
    ]
  end

  defp build(error) when is_map(error) do
    [
      status: nil,
      line: nil,
      col: nil,
      message: error["message"],
      type: nil,
      raw: error
    ]
  end

  defp type(%{"error" => %{"root_cause" => causes}}) do
    get_in(causes, [Access.at(0), "type"])
  end

  defp type(%{"error" => %{"type" => type}}) do
    type
  end
end
