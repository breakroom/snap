defmodule Snap.Suggest.Option do
  @moduledoc """
  Represents an individual `suggest` / `options` dictionary from a [Search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search.html) response.
  """
  defstruct ~w[
    freq
    id
    index
    score
    source
    text
  ]a

  def new(response) do
    %__MODULE__{
      freq: response["freq"],
      id: response["_id"],
      index: response["_index"],
      score: response["score"] || response["_score"],
      source: response["_source"],
      text: response["text"]
    }
  end

  @type t :: %__MODULE__{
          freq: integer(),
          id: String.t() | nil,
          index: String.t() | nil,
          score: float(),
          source: map() | nil,
          text: String.t()
        }
end
