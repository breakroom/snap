defmodule Snap.IntegrationCase do
  use ExUnit.CaseTemplate

  alias Snap.Test.Cluster

  @prefix "snap-test"

  # Clean out any indexes remaining after each test run
  setup do
    {:ok, indexes} = Snap.Indexes.list(Cluster)

    indexes
    |> Enum.filter(&String.starts_with?(&1, @prefix))
    |> Enum.each(fn i ->
      {:ok, _} = Snap.Indexes.delete(Cluster, i)
    end)
  end

  using do
    quote do
      @test_index "snap-test"
    end
  end
end
