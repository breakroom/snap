defmodule Snap.HTTPClient.Response do
  @moduledoc """
  Response of a http request.
  """

  alias Snap.HTTPClient

  defstruct [
    :status,
    body: "",
    headers: []
  ]

  @type status :: non_neg_integer()

  @type t :: %__MODULE__{
          status: status(),
          body: HTTPClient.body(),
          headers: HTTPClient.headers()
        }
end
