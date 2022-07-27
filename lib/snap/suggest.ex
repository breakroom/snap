defmodule Snap.Suggest do
  @moduledoc """
  Represents an individual suggest dictionary from a [Search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search.html) response.
  """
  defstruct ~w[
    length
    offset
    options
    text
  ]a

  def new(response) do
    %__MODULE__{
      length: response["length"],
      offset: response["offset"],
      options: Snap.Suggest.Options.new(response["options"]),
      text: response["text"]
    }
  end

  @type t :: %__MODULE__{
          length: non_neg_integer(),
          offset: non_neg_integer(),
          options: [Snap.Suggest.Option.t()],
          text: String.t()
        }
end
