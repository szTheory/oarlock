defmodule Paddle.ErrorTest do
  use ExUnit.Case, async: true

  alias Paddle.Error

  describe "message/1" do
    test "returns the exception message field" do
      assert Exception.message(%Error{message: "bad request"}) == "bad request"
    end
  end

  describe "from_response/1" do
    test "maps a Paddle API error response into the exception struct" do
      response =
        Req.Response.new(
          status: 422,
          body: %{
            "error" => %{
              "type" => "validation_error",
              "code" => "invalid_field",
              "detail" => "Email is invalid",
              "errors" => [%{"field" => "email", "message" => "must be present"}]
            }
          }
        )
        |> Req.Response.put_header("x-request-id", "req_123")

      assert %Error{
               status_code: 422,
               request_id: "req_123",
               type: "validation_error",
               code: "invalid_field",
               message: "Email is invalid",
               errors: [%{"field" => "email", "message" => "must be present"}],
               raw: %{
                 "error" => %{
                   "type" => "validation_error",
                   "code" => "invalid_field",
                   "detail" => "Email is invalid",
                   "errors" => [%{"field" => "email", "message" => "must be present"}]
                 }
               }
             } = Error.from_response(response)
    end

    test "falls back safely when the response body is not a map" do
      response =
        Req.Response.new(status: 500, body: nil)
        |> Req.Response.put_header("x-request-id", "req_500")

      assert %Error{
               status_code: 500,
               request_id: "req_500",
               type: nil,
               code: nil,
               message: "Unknown Paddle Error",
               errors: [],
               raw: %{}
             } = Error.from_response(response)
    end
  end
end
