defmodule Snap.RequestTest do
  use ExUnit.Case

  alias Snap.Request

  describe "assemble_url/3" do
    test "it assembles with a path" do
      assert Request.assemble_url("http://example.org", "/foo", %{}) == "http://example.org/foo"
    end

    test "it assembles with a path and query params" do
      assert Request.assemble_url("http://example.org", "/foo", %{"foo" => "bar", "baz" => "boz"}) ==
               "http://example.org/foo?baz=boz&foo=bar"
    end

    test "it assembles with a query params and a path with existing query params" do
      assert Request.assemble_url("http://example.org", "/foo?a=b", %{
               "foo" => "bar",
               "baz" => "boz"
             }) ==
               "http://example.org/foo?a=b&baz=boz&foo=bar"
    end
  end
end
