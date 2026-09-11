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
               raw_data: %{
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
               raw_data: %{}
             } = Error.from_response(response)
    end

    test "normalizes malformed nested error members without raising" do
      for malformed <- [nil, "bad-shape", ["bad-shape"], 42] do
        body = %{"error" => malformed, "outer" => "retained"}
        response = Req.Response.new(status: 502, body: body)

        assert %Error{
                 status_code: 502,
                 type: nil,
                 code: nil,
                 message: "Unknown Paddle Error",
                 errors: [],
                 raw_data: ^body
               } = Error.from_response(response)
      end
    end

    test "normalizes atom-keyed and type-invalid nested maps to documented field shapes" do
      malformed_maps = [
        %{type: "atom-type", code: "atom-code", detail: "atom-detail", errors: [%{}]},
        %{
          "type" => :invalid,
          "code" => 123,
          "detail" => ["invalid"],
          "errors" => "invalid"
        }
      ]

      for malformed <- malformed_maps do
        body = %{"error" => malformed}

        assert %Error{
                 type: nil,
                 code: nil,
                 message: "Unknown Paddle Error",
                 errors: [],
                 raw_data: ^body
               } = Error.from_response(Req.Response.new(status: 422, body: body))
      end
    end
  end

  describe "context-aware constructors" do
    test "from_response/2 prefers body meta request_id and marks uncertain mutations" do
      response =
        Req.Response.new(
          status: 503,
          body: %{
            "meta" => %{"request_id" => "body_req_503"},
            "error" => %{"detail" => "Service unavailable"}
          }
        )
        |> Req.Response.put_header("x-request-id", "header_req_503")

      assert %Error{
               request_id: "body_req_503",
               ambiguous?: true,
               retryable?: false,
               operation: :create_transaction,
               resource_id: "txn_01",
               reconciliation: [:lookup, :webhook, :provider_dashboard]
             } =
               Error.from_response(response, %{
                 method: :post,
                 operation: :create_transaction,
                 resource_id: "txn_01"
               })
    end

    test "from_response/2 falls back to x-request-id and leaves definitive errors unambiguous" do
      response =
        Req.Response.new(status: 422, body: %{"meta" => %{}})
        |> Req.Response.put_header("x-request-id", "header_req_422")

      assert %Error{
               request_id: "header_req_422",
               ambiguous?: false,
               reconciliation: []
             } = Error.from_response(response, %{method: :post, operation: :create_customer})
    end

    test "from_transport/2 retains only documented reconciliation values" do
      error =
        Error.from_transport(%Req.TransportError{reason: :closed}, %{
          method: :delete,
          operation: :cancel_subscription,
          resource_id: "sub_01"
        })

      assert error.ambiguous?
      refute error.retryable?
      assert error.reconciliation == [:lookup, :webhook, :provider_dashboard]
      assert Enum.all?(error.reconciliation, &(&1 in [:lookup, :webhook, :provider_dashboard]))
    end
  end

  describe "Inspect" do
    test "redacts raw_data wholesale without altering stored error data" do
      raw_data = %{
        "authorization" => "Bearer raw_error_auth_canary",
        "nested" => [%{"signed_url" => "https://error.test?token=raw_error_url_canary"}]
      }

      error = %Error{
        message: "Safe public message",
        operation: :create_transaction,
        raw_data: raw_data
      }

      inspected = inspect(error)

      assert inspected =~ "raw_data: \"[REDACTED]\""
      assert inspected =~ "operation: :create_transaction"
      assert inspected =~ "Safe public message"
      refute inspected =~ "raw_error_auth_canary"
      refute inspected =~ "raw_error_url_canary"
      assert error.raw_data == raw_data
    end
  end

  describe "struct defaults" do
    test "network_error? defaults to false on a bare struct" do
      assert %Error{network_error?: false} = %Error{}
    end

    test "retryable? defaults to false on a bare struct" do
      assert %Error{retryable?: false} = %Error{}
    end

    test "ambiguity and reconciliation defaults are conservative" do
      assert %Error{ambiguous?: false, operation: nil, resource_id: nil, reconciliation: []} =
               %Error{}
    end

    test "network_error? defaults to false on from_response/1 result" do
      response = Req.Response.new(status: 422, body: %{})
      assert %Error{network_error?: false} = Error.from_response(response)
    end

    test "retryable? defaults to false on from_response/1 result" do
      response = Req.Response.new(status: 422, body: %{})
      assert %Error{retryable?: false} = Error.from_response(response)
    end
  end
end
