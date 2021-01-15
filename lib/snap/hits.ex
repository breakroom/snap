defmodule Snap.Hits do
  @moduledoc """
  Represents the `hits` dictionary returned from an ElasticSearch [Search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search.html) response.

  Implements `Enumerable`, so you can iterate directly over the struct.
  """

  defstruct [:total, :max_score, :hits]

  def new(response) do
    %__MODULE__{
      total: response["total"],
      max_score: response["max_score"],
      hits: build_hits(response["hits"])
    }
  end

  defp build_hits(hits) do
    hits
    |> Enum.map(&Snap.Hit.new/1)
  end

  @type t :: %__MODULE__{
          total: map() | integer(),
          max_score: float() | nil,
          hits: [Snap.Hit.t()]
        }

  defimpl Enumerable do
    def reduce(_, {:halt, acc}, _fun), do: {:halted, acc}

    def reduce(%Snap.Hits{hits: hits}, {:suspend, acc}, fun) do
      {:suspended, acc, &reduce(%Snap.Hits{hits: hits}, &1, fun)}
    end

    def reduce(%Snap.Hits{hits: []}, {:cont, acc}, _fun),
      do: {:done, acc}

    def reduce(%Snap.Hits{hits: [head | tail]}, {:cont, acc}, fun) do
      reduce(%Snap.Hits{hits: tail}, fun.(head, acc), fun)
    end

    def count(%Snap.Hits{hits: hits}) do
      {:ok, Enum.count(hits)}
    end

    def member?(hits, elem) do
      {:ok, Enum.member?(hits.hits, elem)}
    end

    def slice(_response), do: {:error, __MODULE__}
  end
end
