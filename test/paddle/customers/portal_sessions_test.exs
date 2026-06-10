defmodule Paddle.Customers.PortalSessionsTest do
  use ExUnit.Case, async: true
  alias Paddle.Customers.PortalSessions
  alias Paddle.PortalSession
  alias Paddle.Error
  alias Paddle.Client

  describe "create/3" do
    test "successfully creates a portal session without subscription_ids" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :post
          assert request.url.path == "/customers/ctm_01hv8/portal-sessions"
          assert decode_json_body(request.body) == %{}

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
  end

  defp client_with_adapter(adapter) do
    %Client{
      api_key: "sk_test_123",
      environment: :sandbox,
      req: Req.new(base_url: "https://sandbox-api.paddle.com", retry: false, adapter: adapter)
    }
  end

  defp decode_json_body(body) do
    body
    |> IO.iodata_to_binary()
    |> Jason.decode!()
  end
end
