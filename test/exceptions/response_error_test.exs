defmodule Snap.ResponseErrorTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Snap.ResponseError

  describe "exception_from_json/1" do
    test "parses a standard error response with root_cause" do
      json = %{
        "status" => 400,
        "error" => %{
          "root_cause" => [
            %{"type" => "parsing_exception", "reason" => "Unknown key for a START_OBJECT"}
          ],
          "type" => "parsing_exception",
          "reason" => "Unknown key for a START_OBJECT",
          "line" => 1,
          "col" => 2
        }
      }

      exception = ResponseError.exception_from_json(json)

      assert %ResponseError{} = exception
      assert exception.status == 400
      assert exception.line == 1
      assert exception.col == 2
      assert exception.message == "Unknown key for a START_OBJECT"
      assert exception.type == "parsing_exception"
      assert exception.raw == json
    end

    test "extracts type from root_cause when present" do
      json = %{
        "status" => 404,
        "error" => %{
          "root_cause" => [
            %{"type" => "index_not_found_exception", "reason" => "no such index [missing]"}
          ],
          "type" => "index_not_found_exception",
          "reason" => "no such index [missing]"
        }
      }

      exception = ResponseError.exception_from_json(json)

      assert exception.type == "index_not_found_exception"
    end

    test "falls back to error type when root_cause is absent" do
      json = %{
        "status" => 500,
        "error" => %{
          "type" => "some_error_type",
          "reason" => "something went wrong"
        }
      }

      exception = ResponseError.exception_from_json(json)

      assert exception.type == "some_error_type"
      assert exception.message == "something went wrong"
      assert exception.status == 500
      assert exception.line == nil
      assert exception.col == nil
      assert exception.raw == json
    end

    test "parses a raw string error with status" do
      json = %{
        "error" => "Service temporarily unavailable",
        "status" => 503
      }

      exception = ResponseError.exception_from_json(json)

      assert exception.status == 503
      assert exception.message == "Service temporarily unavailable"
      assert exception.type == nil
      assert exception.line == nil
      assert exception.col == nil
      assert exception.raw == json
    end

    test "parses a result-based response" do
      json = %{"result" => "not_found"}

      exception = ResponseError.exception_from_json(json)

      assert exception.type == "not_found"
      assert exception.status == nil
      assert exception.line == nil
      assert exception.col == nil
      assert exception.message == nil
    end

    test "parses a found=false response as document_not_found" do
      json = %{"found" => false}

      exception = ResponseError.exception_from_json(json)

      assert exception.type == "document_not_found"
      assert exception.status == nil
      assert exception.message == nil
    end

    test "parses a generic map with a message field" do
      json = %{"message" => "request body is required"}

      exception = ResponseError.exception_from_json(json)

      assert exception.message == "request body is required"
      assert exception.type == nil
      assert exception.status == nil
      assert exception.line == nil
      assert exception.col == nil
      assert exception.raw == json
    end

    test "parses a generic map without a message field" do
      json = %{"some_key" => "some_value"}

      exception = ResponseError.exception_from_json(json)

      assert exception.message == nil
      assert exception.type == nil
      assert exception.raw == json
    end
  end

  describe "message/1" do
    test "formats message with type and reason" do
      exception =
        ResponseError.exception_from_json(%{
          "status" => 400,
          "error" => %{
            "type" => "parsing_exception",
            "reason" => "Unknown key for a START_OBJECT"
          }
        })

      assert ResponseError.message(exception) ==
               "(parsing_exception) Unknown key for a START_OBJECT"
    end

    test "formats message with only type" do
      exception = ResponseError.exception_from_json(%{"found" => false})

      assert ResponseError.message(exception) == "(document_not_found)"
    end

    test "formats message with only reason" do
      exception = ResponseError.exception_from_json(%{"message" => "request body is required"})

      assert ResponseError.message(exception) == "request body is required"
    end

    test "formats empty message when both type and reason are nil" do
      exception = ResponseError.exception_from_json(%{"some_key" => "value"})

      assert ResponseError.message(exception) == ""
    end
  end
end
