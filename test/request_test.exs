defmodule Snap.RequestTest do
  use Snap.IntegrationCase, async: true

  alias Snap.Request
  alias Snap.Test.Cluster

  describe "path validation" do
    test "rejects `..` traversal in the path" do
      assert {:error, %Snap.InvalidPathError{path: "/users/_doc/x/../../_all"}} =
               Request.request(Cluster, :delete, "/users/_doc/x/../../_all")
    end

    test "rejects leading `..` in the path" do
      assert {:error, %Snap.InvalidPathError{path: "/../foo"}} =
               Request.request(Cluster, :get, "/../foo")
    end

    test "rejects `.` segments" do
      assert {:error, %Snap.InvalidPathError{}} =
               Request.request(Cluster, :get, "/users/./_doc/1")
    end

    test "rejects protocol-relative paths that would redirect to another host" do
      assert {:error, %Snap.InvalidPathError{path: "//evil.com/_doc"}} =
               Request.request(Cluster, :get, "//evil.com/_doc")
    end

    test "rejects paths that are not absolute" do
      assert {:error, %Snap.InvalidPathError{path: "users/_doc/1"}} =
               Request.request(Cluster, :get, "users/_doc/1")
    end

    test "rejects non-binary paths" do
      assert {:error, %Snap.InvalidPathError{path: nil}} =
               Request.request(Cluster, :get, nil)
    end

    test "exposes the offending path in the exception message" do
      {:error, error} = Request.request(Cluster, :get, "/a/../b")
      assert Exception.message(error) =~ "/a/../b"
      assert Exception.message(error) =~ "traversal"
    end

    test "rejects percent-encoded `..` segments" do
      assert {:error, %Snap.InvalidPathError{}} =
               Request.request(Cluster, :get, "/users/_doc/%2E%2E/_all")

      assert {:error, %Snap.InvalidPathError{}} =
               Request.request(Cluster, :get, "/users/_doc/%2e%2e/_all")
    end

    test "rejects percent-encoded `.` segments" do
      assert {:error, %Snap.InvalidPathError{}} =
               Request.request(Cluster, :get, "/users/%2E/_doc/1")

      assert {:error, %Snap.InvalidPathError{}} =
               Request.request(Cluster, :get, "/users/%2e/_doc/1")
    end

    test "rejects percent-encoded slashes that smuggle traversal segments" do
      assert {:error, %Snap.InvalidPathError{}} =
               Request.request(Cluster, :get, "/users/_doc/x%2F..%2F..%2F_all")

      assert {:error, %Snap.InvalidPathError{}} =
               Request.request(Cluster, :get, "/users/_doc/x%2f..%2f..%2f_all")
    end

    test "rejects percent-encoded slash adjacent to a literal slash" do
      assert {:error, %Snap.InvalidPathError{}} =
               Request.request(Cluster, :get, "/users/%2F/_doc/1")
    end

    test "allows legitimate percent-encoded characters that aren't traversal" do
      # A percent-encoded space decodes to " ", which is a legal path segment.
      # We can't easily assert success without hitting Elasticsearch, but we
      # can at least confirm the path validator does not short-circuit with an
      # InvalidPathError.
      refute match?(
               {:error, %Snap.InvalidPathError{}},
               Request.request(Cluster, :get, "/users/_doc/hello%20world")
             )
    end
  end
end
