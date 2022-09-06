defmodule Snap.Multi.Response do
  @moduledoc """
  Represents a successful response for a `Snap.Multi` request.
  """
  defstruct [:searches, :took]

  @type t :: %__MODULE__{
          searches: list({atom(), Snap.SearchResponse.t()})
        }

  alias Snap.SearchResponse

  @doc false
  def new(body, ids) do
    responses = Enum.map(body["responses"], &SearchResponse.new/1)
    took = body["took"]

    searches = Enum.zip(ids, responses)

    %__MODULE__{searches: searches, took: took}
  end
end
