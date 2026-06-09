# This test pins the full oarlock surface that Accrue targets.
# Scope: customer -> address -> transaction -> webhook -> subscription get -> pause -> resume -> cancel.
# Each step uses its own client because adapters are one-shot closures and must not be reused.
defmodule Paddle.SeamTest do
  use ExUnit.Case, async: false

  alias Paddle.Address
  alias Paddle.Client
  alias Paddle.Customer
  alias Paddle.Event
  alias Paddle.Subscription
  alias Paddle.Subscription.ManagementUrls
  alias Paddle.Subscription.ScheduledChange
  alias Paddle.Transaction
  alias Paddle.Transaction.Checkout
  alias Paddle.Webhooks

  @seam_secret "pdl_ntfset_seam_secret"
  @seam_timestamp 1_700_000_000
  @transaction_completed_body ~s({"event_id":"evt_seam01","event_type":"transaction.completed","occurred_at":"2024-04-12T10:37:59Z","notification_id":"ntf_seam01","data":{"id":"txn_seam01","status":"completed","customer_id":"ctm_seam01","subscription_id":"sub_seam01","checkout":{"url":"https://checkout.paddle.com/checkout/txn_seam01"},"currency_code":"USD","collection_mode":"automatic"}})

  test "locks the Accrue seam across the customer, checkout, webhook, and subscription lifecycle flow" do
    customer_client =
      client_with_adapter(fn request ->
        assert request.method == :post
        assert request.url.path == "/customers"

        assert decode_json_body(request.body) == %{
                 "email" => "ada@example.com",
                 "locale" => "en",
                 "name" => "Ada Lovelace"
               }

        {request, Req.Response.new(status: 201, body: %{"data" => customer_payload()})}
      end)

    assert {:ok, %Customer{id: "ctm_seam01", email: "ada@example.com"} = customer} =
             Paddle.Customers.create(customer_client,
               email: "ada@example.com",
               name: "Ada Lovelace",
               locale: "en"
             )

    assert is_map(customer.raw_data)

    portal_session_client =
      client_with_adapter(fn request ->
        assert request.method == :post
        assert request.url.path == "/customers/ctm_seam01/portal-sessions"

        {request, Req.Response.new(status: 201, body: %{"data" => portal_session_payload()})}
      end)

    assert {:ok, %Paddle.PortalSession{id: "pts_seam01", customer_id: "ctm_seam01"} = portal_session} =
             Paddle.Customers.PortalSessions.create(portal_session_client, customer.id)

    assert is_map(portal_session.raw_data)

    address_client =
      client_with_adapter(fn request ->
        assert request.method == :post
        assert request.url.path == "/customers/ctm_seam01/addresses"

        assert decode_json_body(request.body) == %{
                 "city" => "New York",
                 "country_code" => "US",
                 "description" => "Home office",
                 "first_line" => "123 Main Street",
                 "postal_code" => "10001",
                 "region" => "NY",
                 "second_line" => "Suite 4"
               }

        {request, Req.Response.new(status: 201, body: %{"data" => address_payload()})}
      end)

    assert {:ok, %Address{id: "add_seam01", customer_id: "ctm_seam01"} = address} =
             Paddle.Customers.Addresses.create(address_client, customer.id,
               description: "Home office",
               first_line: "123 Main Street",
               second_line: "Suite 4",
               city: "New York",
               postal_code: "10001",
               region: "NY",
               country_code: "US"
             )

    assert is_map(address.raw_data)

    transaction_create_client =
      client_with_adapter(fn request ->
        assert request.method == :post
        assert request.url.path == "/transactions"
        assert Req.Request.get_header(request, "idempotency-key") == ["accrue:seam:txn_seam01"]

        assert decode_json_body(request.body) == %{
                 "address_id" => "add_seam01",
                 "collection_mode" => "automatic",
                 "customer_id" => "ctm_seam01",
                 "items" => [%{"price_id" => "pri_seam01", "quantity" => 1}]
               }

        {request, Req.Response.new(status: 201, body: %{"data" => transaction_payload("ready")})}
      end)

    assert {:ok, %Transaction{id: "txn_seam01"} = transaction} =
             Paddle.Transactions.create(
               transaction_create_client,
               [
                 customer_id: customer.id,
                 address_id: address.id,
                 items: [%{price_id: "pri_seam01", quantity: 1}]
               ],
               idempotency_key: "accrue:seam:txn_seam01"
             )

    assert %Checkout{url: checkout_url} = transaction.checkout
    assert checkout_url == "https://checkout.paddle.com/checkout/txn_seam01"
    assert is_map(transaction.checkout.raw_data)

    transaction_get_client =
      client_with_adapter(fn request ->
        assert request.method == :get
        assert request.url.path == "/transactions/txn_seam01"
        assert request.body == nil

        {request,
         Req.Response.new(status: 200, body: %{"data" => transaction_payload("completed")})}
      end)

    assert {:ok,
            %Transaction{
              id: "txn_seam01",
              customer_id: "ctm_seam01",
              subscription_id: "sub_seam01"
            } = fetched_transaction} =
             Paddle.Transactions.get(transaction_get_client, transaction.id)

    assert %Checkout{url: "https://checkout.paddle.com/checkout/txn_seam01"} =
             fetched_transaction.checkout

    assert is_map(fetched_transaction.checkout.raw_data)

    header = signature_header(@transaction_completed_body, @seam_secret, @seam_timestamp)

    assert {:ok, :verified} =
             Webhooks.verify_signature(
               @transaction_completed_body,
               header,
               @seam_secret,
               now: @seam_timestamp
             )

    assert {:ok,
            %Event{
              event_id: "evt_seam01",
              event_type: "transaction.completed",
              notification_id: "ntf_seam01"
            } = event} = Webhooks.parse_event(@transaction_completed_body)

    assert is_map(event.raw_data)

    adjustment_client =
      client_with_adapter(fn request ->
        assert request.method == :post
        assert request.url.path == "/adjustments"

        assert decode_json_body(request.body) == %{
                 "action" => "refund",
                 "reason" => "fraud",
                 "transaction_id" => "txn_seam01",
                 "items" => [%{"item_id" => "pri_seam01", "type" => "full"}]
               }

        {request, Req.Response.new(status: 201, body: %{"data" => adjustment_payload()})}
      end)

    assert {:ok, %Paddle.Adjustment{id: "adj_seam01"} = adjustment} =
             Paddle.Adjustments.create(adjustment_client,
               action: "refund",
               reason: "fraud",
               transaction_id: "txn_seam01",
               items: [%{item_id: "pri_seam01", type: "full"}]
             )

    assert is_map(adjustment.raw_data)

    refute function_exported?(Paddle.Subscriptions, :create, 2)

    subscription_get_client =
      client_with_adapter(fn request ->
        assert request.method == :get
        assert request.url.path == "/subscriptions/sub_seam01"
        assert request.body == nil

        {request, Req.Response.new(status: 200, body: %{"data" => subscription_payload()})}
      end)

    assert {:ok, %Subscription{id: "sub_seam01", status: "active"} = subscription} =
             Paddle.Subscriptions.get(
               subscription_get_client,
               fetched_transaction.subscription_id
             )

    assert %ManagementUrls{
             update_payment_method:
               "https://buyer-portal.paddle.com/subscriptions/sub_seam01/update-payment-method",
             cancel: "https://buyer-portal.paddle.com/subscriptions/sub_seam01/cancel"
           } = subscription.management_urls

    pause_client =
      client_with_adapter(fn request ->
        assert request.method == :post
        assert request.url.path == "/subscriptions/sub_seam01/pause"

        assert decode_json_body(request.body) == %{
                 "effective_from" => "next_billing_period",
                 "on_resume" => "start_new_billing_period"
               }

        {request, Req.Response.new(status: 200, body: %{"data" => subscription_payload_paused()})}
      end)

    assert {:ok, %Subscription{status: "active"} = paused_subscription} =
             Paddle.Subscriptions.pause(
               pause_client,
               subscription.id,
               on_resume: :start_new_billing_period
             )

    assert %ScheduledChange{action: "pause"} = paused_subscription.scheduled_change
    assert is_map(paused_subscription.raw_data)

    resume_client =
      client_with_adapter(fn request ->
        assert request.method == :post
        assert request.url.path == "/subscriptions/sub_seam01/resume"
        assert decode_json_body(request.body) == %{"effective_from" => "immediately"}

        {request,
         Req.Response.new(status: 200, body: %{"data" => subscription_payload_resumed()})}
      end)

    assert {:ok, %Subscription{status: "active"} = resumed_subscription} =
             Paddle.Subscriptions.resume(resume_client, subscription.id)

    assert resumed_subscription.scheduled_change == nil
    assert is_map(resumed_subscription.raw_data)

    cancel_client =
      client_with_adapter(fn request ->
        assert request.method == :post
        assert request.url.path == "/subscriptions/sub_seam01/cancel"
        assert decode_json_body(request.body) == %{"effective_from" => "next_billing_period"}

        {request,
         Req.Response.new(status: 200, body: %{"data" => subscription_payload_canceled()})}
      end)

    assert {:ok,
            %Subscription{
              id: "sub_seam01",
              status: "active",
              scheduled_change: %ScheduledChange{
                action: "cancel",
                effective_at: "2024-05-12T10:37:59.556997Z",
                resume_at: nil
              }
            } = canceled_subscription} =
             Paddle.Subscriptions.cancel(cancel_client, subscription.id)

    assert is_map(canceled_subscription.scheduled_change.raw_data)
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

  defp signature_header(raw_body, secret, timestamp) do
    "ts=#{timestamp};h1=#{signature(timestamp, raw_body, secret)}"
  end

  defp signature(timestamp, raw_body, secret) do
    :crypto.mac(:hmac, :sha256, secret, "#{timestamp}:#{raw_body}")
    |> Base.encode16(case: :lower)
  end

  defp customer_payload do
    %{
      "id" => "ctm_seam01",
      "name" => "Ada Lovelace",
      "email" => "ada@example.com",
      "marketing_consent" => false,
      "status" => "active",
      "custom_data" => %{},
      "locale" => "en",
      "created_at" => "2024-04-12T10:15:30Z",
      "updated_at" => "2024-04-13T11:16:31Z",
      "import_meta" => %{}
    }
  end

  defp address_payload do
    %{
      "id" => "add_seam01",
      "customer_id" => "ctm_seam01",
      "description" => "Home office",
      "first_line" => "123 Main Street",
      "second_line" => "Suite 4",
      "city" => "New York",
      "postal_code" => "10001",
      "region" => "NY",
      "country_code" => "US",
      "custom_data" => %{},
      "status" => "active",
      "created_at" => "2024-04-12T10:20:30Z",
      "updated_at" => "2024-04-12T10:20:31Z",
      "import_meta" => %{}
    }
  end

  defp transaction_payload(status) do
    %{
      "id" => "txn_seam01",
      "status" => status,
      "customer_id" => "ctm_seam01",
      "address_id" => "add_seam01",
      "business_id" => nil,
      "custom_data" => %{},
      "currency_code" => "USD",
      "origin" => "api",
      "subscription_id" => if(status == "completed", do: "sub_seam01", else: nil),
      "invoice_number" => nil,
      "collection_mode" => "automatic",
      "items" => [%{"price_id" => "pri_seam01", "quantity" => 1}],
      "details" => %{"totals" => %{"subtotal" => "1000"}},
      "payments" => [],
      "checkout" => %{"url" => "https://checkout.paddle.com/checkout/txn_seam01"},
      "created_at" => "2024-04-12T10:25:30Z",
      "updated_at" => "2024-04-12T10:25:31Z",
      "billed_at" => if(status == "completed", do: "2024-04-12T10:37:59Z", else: nil),
      "revised_at" => nil
    }
  end

  defp subscription_payload do
    %{
      "id" => "sub_seam01",
      "status" => "active",
      "customer_id" => "ctm_seam01",
      "address_id" => "add_seam01",
      "business_id" => nil,
      "currency_code" => "USD",
      "collection_mode" => "automatic",
      "custom_data" => %{},
      "items" => [%{"price" => %{"id" => "pri_seam01"}, "quantity" => 1}],
      "scheduled_change" => nil,
      "management_urls" => %{
        "update_payment_method" =>
          "https://buyer-portal.paddle.com/subscriptions/sub_seam01/update-payment-method",
        "cancel" => "https://buyer-portal.paddle.com/subscriptions/sub_seam01/cancel"
      },
      "current_billing_period" => %{
        "starts_at" => "2024-04-12T10:37:59.556997Z",
        "ends_at" => "2024-05-12T10:37:59.556997Z"
      },
      "billing_cycle" => %{
        "interval" => "month",
        "frequency" => 1
      },
      "billing_details" => nil,
      "discount" => nil,
      "next_billed_at" => "2024-05-12T10:37:59.556997Z",
      "started_at" => "2024-04-12T10:37:59.556997Z",
      "first_billed_at" => "2024-04-12T10:37:59.556997Z",
      "paused_at" => nil,
      "canceled_at" => nil,
      "created_at" => "2024-04-12T10:37:59.556997Z",
      "updated_at" => "2024-04-12T10:37:59.556997Z",
      "import_meta" => %{}
    }
  end

  defp subscription_payload_canceled do
    Map.merge(subscription_payload(), %{
      "scheduled_change" => %{
        "action" => "cancel",
        "effective_at" => "2024-05-12T10:37:59.556997Z",
        "resume_at" => nil
      },
      "updated_at" => "2024-04-13T10:37:59.556997Z"
    })
  end

  defp subscription_payload_paused do
    Map.merge(subscription_payload(), %{
      "scheduled_change" => %{
        "action" => "pause",
        "effective_at" => "2024-05-12T10:37:59.556997Z",
        "resume_at" => nil
      },
      "updated_at" => "2024-04-13T09:37:59.556997Z"
    })
  end

  defp subscription_payload_resumed do
    Map.merge(subscription_payload(), %{
      "scheduled_change" => nil,
      "updated_at" => "2024-04-13T09:47:59.556997Z"
    })
  end

  defp portal_session_payload do
    %{
      "id" => "pts_seam01",
      "customer_id" => "ctm_seam01",
      "urls" => %{
        "general" => %{"overview" => "https://buyer-portal.paddle.com/pts_seam01"},
        "subscriptions" => [%{"id" => "sub_seam01", "cancel" => "https://buyer-portal.paddle.com/cancel/sub_seam01"}]
      },
      "custom_data" => %{},
      "created_at" => "2024-04-12T10:16:30Z"
    }
  end

  defp adjustment_payload do
    %{
      "id" => "adj_seam01",
      "action" => "refund",
      "transaction_id" => "txn_seam01",
      "subscription_id" => "sub_seam01",
      "customer_id" => "ctm_seam01",
      "reason" => "fraud",
      "credit_applied_to_balance" => false,
      "currency_code" => "USD",
      "status" => "pending_approval",
      "items" => [],
      "totals" => %{"subtotal" => "1000", "tax" => "0", "total" => "1000", "fee" => "0", "earnings" => "1000"},
      "payouts" => %{"subtotal" => "1000", "tax" => "0", "total" => "1000", "fee" => "0", "earnings" => "1000"},
      "created_at" => "2024-04-12T10:38:00Z",
      "updated_at" => "2024-04-12T10:38:00Z"
    }
  end

  test "sealed modules remain undocumented" do
    for module <- [
          Paddle,
          Paddle.Http,
          Paddle.Http.Telemetry,
          Paddle.Application,
          Paddle.Internal.Attrs,
          Paddle.Internal.Pagination
        ] do
      assert {:docs_v1, _, _, _, :hidden, _, _} = Code.fetch_docs(module)
    end
  end
end
