defmodule Snap.IntegrationCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  alias Snap.Cluster.Namespace
  alias Snap.Test

  alias Snap.Test.Cluster

  # Clean out any indexes remaining after each test run
  setup do
    namespace = Test.generate_namespace_for_pid(self())
    Namespace.set_process_namespace(Cluster, namespace)
    Test.drop_indexes(Cluster)

    on_exit(fn ->
      Namespace.set_process_namespace(Cluster, namespace)
      Test.drop_indexes(Cluster)
    end)
  end

  using do
    quote do
      @moduletag :integration
    end
  end
end
