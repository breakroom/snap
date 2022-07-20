defmodule Snap.Suggest.Option do
  @moduledoc """
  Represents an individual `suggest` / `options` dictionary from a [Search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search.html) response.
  """
  defstruct ~w[
    freq
    score
    text
  ]a

  def new(response) do
    %__MODULE__{
      freq: response["freq"],
      score: response["score"],
      text: response["text"]
    }
  end

  @type t :: %__MODULE__{
          freq: integer(),
          score: float(),
          text: String.t()
        }
end
