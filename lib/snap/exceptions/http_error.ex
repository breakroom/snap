defmodule Snap.HTTPError do
  @moduledoc """
  Represents an HTTP error returned while executing a query.
  """

  alias Snap.HTTPClient

  @keys [
    :status,
    :body,
    :headers
  ]

  @enforce_keys @keys
  defexception @keys

  def exception_from_response(%HTTPClient.Response{status: status, body: body, headers: headers}) do
    %__MODULE__{status: status, body: body, headers: headers}
  end

  def message(%__MODULE__{} = e) do
    "HTTP status #{e.status}"
  end
end
