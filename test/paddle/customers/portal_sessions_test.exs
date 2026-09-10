defmodule Paddle.Customers.PortalSessionsTest do
  use ExUnit.Case, async: true

  defmodule Adapter do
    def run(request) do
      request
      |> Req.Request.get_private(:paddle_test_adapter)
      |> then(& &1.(request))
    end
  end

  alias Paddle.Customers.PortalSessions
  alias Paddle.PortalSession
  alias Paddle.PortalSessions, as: LegacyPortalSessions
  alias Paddle.Error
  alias Paddle.Client

  describe "create/3" do
    test "successfully creates a portal session without subscription_ids" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :post
          assert request.url.path == "/customers/ctm_01hv8/portal-sessions"
          assert decode_json_body(request.body) == %{}

          assert request_context(request) == %{
                   method: :post,
                   operation: :create_customer_portal_session,
                   resource_id: "ctm_01hv8",
                   route: "/customers/:customer_id/portal-sessions"
                 }

          {request,
           Req.Response.new(
             status: 201,
             body: %{
               "data" => %{
                 "id" => "cptrsess_01hv8",
                 "customer_id" => "ctm_01hv8",
                 "urls" => %{
                   "general" => %{
                     "overview" => "https://buy.paddle.com/portal/session/overview?secret=1"
                   }
                 },
                 "created_at" => "2024-04-12T10:49:57.652Z",
                 "custom_data" => nil
               }
             }
           )}
        end)

      assert {:ok, %PortalSession{} = session} = PortalSessions.create(client, "ctm_01hv8", %{})

      assert session.id == "cptrsess_01hv8"
      assert session.customer_id == "ctm_01hv8"

      assert session.urls["general"]["overview"] ==
               "https://buy.paddle.com/portal/session/overview?secret=1"
    end

    test "successfully creates a portal session with subscription_ids" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :post
          assert request.url.path == "/customers/ctm_01hv8/portal-sessions"
          assert decode_json_body(request.body) == %{"subscription_ids" => ["sub_01hvg"]}

          {request,
           Req.Response.new(
             status: 201,
             body: %{
               "data" => %{
                 "id" => "cptrsess_01hv8",
                 "customer_id" => "ctm_01hv8",
                 "urls" => %{
                   "subscriptions" => [
                     %{
                       "id" => "sub_01hvg",
                       "cancel_subscription" =>
                         "https://buy.paddle.com/portal/session/cancel-subscription?secret=2"
                     }
                   ]
                 }
               }
             }
           )}
        end)

      assert {:ok, %PortalSession{} = session} =
               PortalSessions.create(client, "ctm_01hv8", subscription_ids: ["sub_01hvg"])

      assert session.id == "cptrsess_01hv8"

      assert hd(session.urls["subscriptions"])["cancel_subscription"] ==
               "https://buy.paddle.com/portal/session/cancel-subscription?secret=2"
    end

    test "returns :invalid_customer_id if customer_id is empty" do
      client = client_with_adapter(fn _ -> flunk("should not be called") end)

      assert {:error, :invalid_customer_id} = PortalSessions.create(client, "", %{})
      assert {:error, :invalid_customer_id} = PortalSessions.create(client, "   ", %{})
      assert {:error, :invalid_customer_id} = PortalSessions.create(client, nil, %{})
    end

    test "handles API errors" do
      client =
        client_with_adapter(fn request ->
          {request,
           Req.Response.new(
             status: 404,
             body: %{
               "error" => %{
                 "type" => "not_found",
                 "code" => "customer_not_found",
                 "detail" => "Customer not found",
                 "errors" => []
               }
             }
           )}
        end)

      assert {:error, %Error{} = error} = PortalSessions.create(client, "ctm_invalid")
      assert error.code == "customer_not_found"
    end

    test "makes one attempt and exposes customer-safe ambiguity without idempotency support" do
      {:ok, attempts} = Agent.start_link(fn -> 0 end)

      client =
        client_with_adapter(fn request ->
          Agent.update(attempts, &(&1 + 1))
          {request, %Req.TransportError{reason: :timeout}}
        end)

      expected_error = %{
        ambiguous?: true,
        retryable?: false,
        operation: :create_customer_portal_session,
        resource_id: "ctm_01hv8",
        reconciliation: [:lookup, :webhook, :provider_dashboard]
      }

      assert {:error, %Error{} = canonical_error} =
               PortalSessions.create(client, "ctm_01hv8", %{})

      assert Map.take(canonical_error, Map.keys(expected_error)) == expected_error
      assert Agent.get(attempts, & &1) == 1

      assert {:error, %Error{} = legacy_error} =
               LegacyPortalSessions.create(client, %{customer_id: "ctm_01hv8"})

      assert Map.take(legacy_error, Map.keys(expected_error)) == expected_error
      assert Agent.get(attempts, & &1) == 2

      assert_raise ArgumentError, ~r/idempotency_key is not supported/, fn ->
        PortalSessions.create(client, "ctm_01hv8", %{}, idempotency_key: "idem_forbidden")
      end

      assert Agent.get(attempts, & &1) == 2
    end
  end

  describe "Paddle.PortalSessions.create/2 compatibility" do
    test "delegates encoded dispatch, filtered attrs, and static context to the canonical path" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :post
          assert request.url.path == "/customers/ctm%2F01/portal-sessions"
          assert decode_json_body(request.body) == %{"subscription_ids" => ["sub_01hvg"]}

          assert request_context(request) == %{
                   method: :post,
                   operation: :create_customer_portal_session,
                   resource_id: "ctm/01",
                   route: "/customers/:customer_id/portal-sessions"
                 }

          {request,
           Req.Response.new(status: 201, body: %{"data" => portal_session_payload("ctm/01")})}
        end)

      assert {:ok, %PortalSession{customer_id: "ctm/01"}} =
               LegacyPortalSessions.create(client, %{
                 customer_id: "ctm/01",
                 subscription_ids: ["sub_01hvg"],
                 ignored: "drop me"
               })
    end

    test "preserves wrapper validation before canonical dispatch" do
      client =
        client_with_adapter(fn request -> flunk("unexpected request: #{inspect(request)}") end)

      assert {:error, :invalid_attrs} = LegacyPortalSessions.create(client, "nope")
      assert {:error, :invalid_customer_id} = LegacyPortalSessions.create(client, %{})
    end
  end

  defp client_with_adapter(adapter) do
    %Client{
      api_key: "sk_test_123",
      environment: :sandbox,
      base_url: "https://sandbox-api.paddle.com",
      req:
        Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: Adapter)
        |> Req.Request.put_private(:paddle_test_adapter, adapter)
    }
  end

  defp decode_json_body(body) do
    body
    |> IO.iodata_to_binary()
    |> Jason.decode!()
  end

  defp request_context(request) do
    Req.Request.get_private(request, :paddle_request_context)
  end

  defp portal_session_payload(customer_id) do
    %{
      "id" => "cptrsess_01hv8",
      "customer_id" => customer_id,
      "urls" => %{"general" => %{"overview" => "https://buy.paddle.com/portal/session"}}
    }
  end
end
