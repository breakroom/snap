defmodule Snap.Suggests do
  @moduledoc """
  Represents the `suggest` dictionary returned from an ElasticSearch [Search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search.html) response.
  """

  def new(response)
  def new(nil), do: nil

  def new(response),
    do:
      Map.new(response, fn {name, suggest} -> {name, Enum.map(suggest, &Snap.Suggest.new(&1))} end)

  @type t :: %{String.t() => [Snap.Suggest.t()]}
end
