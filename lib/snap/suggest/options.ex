defmodule Snap.Suggest.Options do
  @moduledoc """
  Represents the `suggest` / `options` dictionary returned from an ElasticSearch [Search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search.html) response.
  """

  def new(response), do: Enum.map(response, &Snap.Suggest.Option.new/1)

  @type t :: [Snap.Suggest.Option.t()]
end
