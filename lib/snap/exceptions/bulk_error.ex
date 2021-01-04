defmodule Snap.BulkError do
  @moduledoc """
  Represents a list of errors, collected from a `Snap.Bulk` operation.
  """
  @enforce_keys [:message, :errors]
  defexception [:message, :errors]

  @type t :: %__MODULE__{
          message: String.t(),
          errors: [Snap.Exception.t()]
        }

  def exception(errors) do
    count = Enum.count(errors)
    str = if count == 1, do: "error", else: "errors"

    message = "#{count} #{str} occurred"

    %__MODULE__{message: message, errors: errors}
  end
end
