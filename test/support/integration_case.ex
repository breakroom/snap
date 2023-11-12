defmodule Snap.IntegrationCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  alias Snap.Cluster.Namespace
  alias Snap.Test

  alias Snap.Test.Cluster

  setup_all do
    # Just clean out anything left over from broken tests in the past in the
    # `snap-test` cluster namespace.
    Test.drop_indexes(Cluster)
  end

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
