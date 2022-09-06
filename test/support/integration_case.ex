defmodule Snap.IntegrationCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  alias Snap.Test.Cluster

  @prefix "snap-test"

  setup_all do
    clear_indexes()
  end

  # Clean out any indexes remaining after each test run
  setup do
    on_exit(fn ->
      clear_indexes()
    end)
  end

  defp clear_indexes() do
    {:ok, indexes} = Snap.Indexes.list(Cluster)

    indexes
    |> Enum.filter(&String.starts_with?(&1, @prefix))
    |> Enum.each(fn i ->
      {:ok, _} = Snap.Indexes.delete(Cluster, i)
    end)
  end

  using do
    quote do
      @moduletag :integration
      @test_index "snap-test"
    end
  end
end
