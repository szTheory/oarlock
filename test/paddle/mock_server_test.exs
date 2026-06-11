defmodule Paddle.MockServerTest do
  use ExUnit.Case, async: false
  
  alias Paddle.MockServer

  setup_all do
    # Start the mock server on a dedicated test port
    port = 4447
    {:ok, _pid} = MockServer.start_link(port: port)
    
    # Configure the client to hit the local mock server
    client = Paddle.Client.new!(
      api_key: "sk_test_mock",
      base_url: "http://localhost:#{port}"
    )

    {:ok, client: client}
  end

  test "POST /customers returns a mocked customer payload", %{client: client} do
    assert {:ok, %Paddle.Customer{} = customer} = Paddle.Customers.create(client, %{email: "test@example.com", name: "Test"})
    assert customer.id == "ctm_mock123"
    assert customer.email == "mock@example.com"
  end

  test "GET /customers/:id dynamically injects the requested ID", %{client: client} do
    assert {:ok, %Paddle.Customer{} = customer} = Paddle.Customers.get(client, "ctm_dynamic_789")
    assert customer.id == "ctm_dynamic_789"
  end

  test "PATCH /customers/:id returns a mocked customer payload", %{client: client} do
    assert {:ok, %Paddle.Customer{} = customer} = Paddle.Customers.update(client, "ctm_dynamic_789", %{name: "Updated"})
    assert customer.id == "ctm_dynamic_789"
  end

  test "POST /transactions returns a mocked transaction payload", %{client: client} do
    assert {:ok, %Paddle.Transaction{} = txn} = Paddle.Transactions.create(client, %{customer_id: "ctm_123", address_id: "add_123", items: [%{price_id: "pri_123", quantity: 1}]})
    assert txn.id == "txn_mock123"
    assert txn.checkout.url == "https://sandbox-checkout.paddle.com/mock-checkout-url"
  end

  test "GET /transactions/:id dynamically injects the requested ID", %{client: client} do
    assert {:ok, %Paddle.Transaction{} = txn} = Paddle.Transactions.get(client, "txn_dynamic_456")
    assert txn.id == "txn_dynamic_456"
  end

  test "POST /customers/:id/portal-sessions dynamically injects the customer_id", %{client: client} do
    assert {:ok, %Paddle.PortalSession{} = session} = Paddle.PortalSessions.create(client, %{customer_id: "ctm_portal_test"})
    assert session.customer_id == "ctm_portal_test"
    assert session.urls["general"]["url"] == "https://sandbox-my.paddle.com/mock-portal-session"
  end

  test "PATCH /subscriptions/:id returns a mocked subscription updated payload for immediate proration", %{client: client} do
    assert {:ok, %Paddle.Subscription{} = sub} = Paddle.Subscriptions.update(client, "sub_mock456", %{proration_billing_mode: "prorated_immediately"})
    assert sub.id == "sub_mock456"
    assert sub.scheduled_change == nil
  end

  test "PATCH /subscriptions/:id returns a mocked scheduled change payload for next billing period", %{client: client} do
    assert {:ok, %Paddle.Subscription{} = sub} = Paddle.Subscriptions.update(client, "sub_mock456", %{proration_billing_mode: "next_billing_period"})
    assert sub.id == "sub_mock456"
    assert %Paddle.Subscription.ScheduledChange{action: "pause", effective_at: "2026-12-01T12:00:00Z"} = sub.scheduled_change
  end

  test "Fallback route returns 404 for unknown endpoints", %{client: client} do
    # Triggering an unknown path natively via Req to test the fallback router
    response = Req.get!("#{client.base_url}/unknown-endpoint")
    assert response.status == 404
    assert response.body["error"]["message"] == "Mock route not found"
  end
end
