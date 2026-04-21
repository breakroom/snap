defmodule Snap.RequestTest do
  use ExUnit.Case, async: true

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
  end
end
