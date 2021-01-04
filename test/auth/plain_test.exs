defmodule Snap.Auth.PlainTest do
  use ExUnit.Case

  alias Snap.Auth.Plain

  test "without a username and password in the config" do
    config = []
    method = "GET"
    path = "/_cluster/health"
    headers = []
    body = nil

    {:ok, {method2, path2, headers2, body2}} = Plain.sign(config, method, path, headers, body)
    assert method == method2
    assert path == path2
    assert headers == headers2
    assert body == body2
  end

  test "with a username and password in the config" do
    config = [username: "testing", password: "password"]
    method = "GET"
    path = "/_cluster/health"
    headers = []
    body = nil

    {:ok, {method2, path2, headers2, body2}} = Plain.sign(config, method, path, headers, body)
    assert method == method2
    assert path == path2
    assert headers2 == [{"Authorization", "Basic dGVzdGluZzpwYXNzd29yZA=="}]
    assert body == body2
  end

  test "with a username and password in the config's URL" do
    config = [url: "http://testing:password@example.net:9200"]
    method = "GET"
    path = "/_cluster/health"
    headers = []
    body = nil

    {:ok, {method2, path2, headers2, body2}} = Plain.sign(config, method, path, headers, body)
    assert method == method2
    assert path == path2
    assert headers2 == [{"Authorization", "Basic dGVzdGluZzpwYXNzd29yZA=="}]
    assert body == body2
  end
end
