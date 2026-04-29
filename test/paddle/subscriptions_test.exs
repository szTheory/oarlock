# All Phase 5 transport tests use Req.new(adapter: ...) exclusively.
# Cancellation is destructive and irreversible per Paddle docs:
# https://developer.paddle.com/api-reference/subscriptions/cancel-subscription
# Do NOT add @tag :integration tests that hit the live or sandbox API.
defmodule Paddle.SubscriptionsTest do
  use ExUnit.Case, async: true

  alias Paddle.Client
  alias Paddle.Error
  alias Paddle.Page
  alias Paddle.Subscription
  alias Paddle.Subscription.ManagementUrls
  alias Paddle.Subscription.ScheduledChange
  alias Paddle.Subscriptions

  describe "get/2" do
    test "issues GET /subscriptions/{id} and returns a typed canceled subscription with hydrated management_urls and nil scheduled_change" do
      response_data = subscription_payload_canceled()

      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/subscriptions/sub_01"
          assert request.body == nil

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok, %Subscription{} = subscription} = Subscriptions.get(client, "sub_01")
      assert subscription.id == "sub_01"
      assert subscription.status == "canceled"
      assert subscription.scheduled_change == nil
      assert subscription.raw_data == response_data

      assert %ManagementUrls{
               update_payment_method:
                 "https://buyer-portal.paddle.com/subscriptions/sub_01/update-payment-method",
               cancel: "https://buyer-portal.paddle.com/subscriptions/sub_01/cancel"
             } = subscription.management_urls

      assert subscription.management_urls.raw_data == response_data["management_urls"]
    end

    test "hydrates scheduled_change as a typed %ScheduledChange{} when populated" do
      response_data = subscription_payload_active_with_scheduled_change()

      client =
        client_with_adapter(fn request ->
          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok, %Subscription{status: "active"} = subscription} =
               Subscriptions.get(client, "sub_01")

      assert %ScheduledChange{
               action: "cancel",
               effective_at: "2024-05-12T10:37:59.556997Z",
               resume_at: nil
             } = subscription.scheduled_change

      assert subscription.scheduled_change.raw_data == response_data["scheduled_change"]
    end

    test "url-encodes subscription ids with reserved characters in the request path" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/subscriptions/sub%2Fwith%3Freserved"

          {request,
           Req.Response.new(status: 200, body: %{"data" => subscription_payload_canceled()})}
        end)

      assert {:ok, %Subscription{}} = Subscriptions.get(client, "sub/with?reserved")
    end

    test "returns :invalid_subscription_id for nil/blank/whitespace/integer ids without dispatching HTTP" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      assert {:error, :invalid_subscription_id} = Subscriptions.get(client, nil)
      assert {:error, :invalid_subscription_id} = Subscriptions.get(client, "")
      assert {:error, :invalid_subscription_id} = Subscriptions.get(client, "   ")
      assert {:error, :invalid_subscription_id} = Subscriptions.get(client, 42)
    end

    test "preserves a 404 entity_not_found %Paddle.Error{} unchanged" do
      client =
        client_with_adapter(fn request ->
          response =
            Req.Response.new(
              status: 404,
              body: %{
                "error" => %{
                  "type" => "request_error",
                  "code" => "entity_not_found",
                  "detail" => "Subscription not found",
                  "errors" => []
                }
              }
            )
            |> Req.Response.put_header("x-request-id", "req_404")

          {request, response}
        end)

      assert {:error,
              %Error{
                status_code: 404,
                request_id: "req_404",
                type: "request_error",
                code: "entity_not_found",
                message: "Subscription not found"
              }} = Subscriptions.get(client, "sub_missing")
    end

    test "surfaces transport exceptions unchanged" do
      client =
        client_with_adapter(fn request ->
          {request, %Req.TransportError{reason: :timeout}}
        end)

      assert {:error, %Req.TransportError{reason: :timeout}} =
               Subscriptions.get(client, "sub_01")
    end

    test "maps update_payment_method to nil for manual-collection subscriptions (Pitfall 5)" do
      response_data = subscription_payload_manual_no_payment_link()

      client =
        client_with_adapter(fn request ->
          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok, %Subscription{} = subscription} = Subscriptions.get(client, "sub_01")

      assert %ManagementUrls{
               update_payment_method: nil,
               cancel: "https://buyer-portal.paddle.com/subscriptions/sub_01/cancel"
             } = subscription.management_urls
    end
  end

  describe "list/2" do
    test "returns a typed %Paddle.Page with hydrated nested structs and a working full-URL next cursor" do
      response_data = [
        subscription_payload_active_with_scheduled_change(),
        Map.merge(subscription_payload_active_with_scheduled_change(), %{"id" => "sub_02"})
      ]

      meta = %{
        "request_id" => "170e71a2-ed13-4f45-b002-45693f5361b4",
        "pagination" => %{
          "per_page" => 50,
          "next" => "https://api.paddle.com/subscriptions?after=sub_01hv8x29kz0t586xy6zn1a62ny",
          "has_more" => false,
          "estimated_total" => 1
        }
      }

      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/subscriptions"
          assert URI.decode_query(request.url.query || "") == %{}
          assert request.body == nil

          {request,
           Req.Response.new(status: 200, body: %{"data" => response_data, "meta" => meta})}
        end)

      assert {:ok,
              %Page{data: [%Subscription{id: "sub_01"}, %Subscription{id: "sub_02"}], meta: ^meta} =
                page} = Subscriptions.list(client)

      assert Page.next_cursor(page) ==
               "https://api.paddle.com/subscriptions?after=sub_01hv8x29kz0t586xy6zn1a62ny"

      # Per-list-item nested-struct hydration (T-05-14): EVERY item runs through build_subscription/1.
      assert %ManagementUrls{
               cancel: "https://buyer-portal.paddle.com/subscriptions/sub_01/cancel"
             } = Enum.at(page.data, 0).management_urls

      assert %ScheduledChange{action: "cancel"} = Enum.at(page.data, 0).scheduled_change

      assert %ManagementUrls{} = Enum.at(page.data, 1).management_urls
      assert %ScheduledChange{action: "cancel"} = Enum.at(page.data, 1).scheduled_change
    end

    test "forwards exactly the 11 D-12 allowlisted query params and drops unsupported keys" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/subscriptions"

          decoded = URI.decode_query(request.url.query)

          assert decoded == %{
                   "id" => "sub_01",
                   "customer_id" => "ctm_01",
                   "address_id" => "add_01",
                   "price_id" => "pri_01",
                   "status" => "active",
                   "scheduled_change_action" => "cancel",
                   "collection_mode" => "automatic",
                   "next_billed_at" => "2024-05-12T10:37:59.556997Z",
                   "order_by" => "created_at[DESC]",
                   "after" => "cursor_123",
                   "per_page" => "50"
                 }

          refute Map.has_key?(decoded, "ignored")

          {request, Req.Response.new(status: 200, body: %{"data" => [], "meta" => %{}})}
        end)

      assert {:ok, %Page{data: [], meta: %{}}} =
               Subscriptions.list(client,
                 id: "sub_01",
                 customer_id: "ctm_01",
                 address_id: "add_01",
                 price_id: "pri_01",
                 status: "active",
                 scheduled_change_action: "cancel",
                 collection_mode: "automatic",
                 next_billed_at: "2024-05-12T10:37:59.556997Z",
                 order_by: "created_at[DESC]",
                 after: "cursor_123",
                 per_page: 50,
                 ignored: "drop me"
               )
    end

    test "satisfies SUB-02 (D-11) by passing customer_id: as a list filter" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/subscriptions"
          assert URI.decode_query(request.url.query) == %{"customer_id" => "ctm_01"}

          {request, Req.Response.new(status: 200, body: %{"data" => [], "meta" => %{}})}
        end)

      assert {:ok, %Page{data: [], meta: %{}}} =
               Subscriptions.list(client, customer_id: "ctm_01")
    end

    test "returns :invalid_params for non-keyword/non-map containers without dispatching HTTP" do
      client =
        client_with_adapter(
          &{&1, Req.Response.new(status: 200, body: %{"data" => [], "meta" => %{}})}
        )

      assert {:error, :invalid_params} = Subscriptions.list(client, "nope")
      assert {:error, :invalid_params} = Subscriptions.list(client, 42)
      assert {:error, :invalid_params} = Subscriptions.list(client, [1, 2, 3])
    end

    test "preserves an empty list response with empty meta" do
      meta = %{
        "pagination" => %{
          "per_page" => 50,
          "next" => nil,
          "has_more" => false,
          "estimated_total" => 0
        }
      }

      client =
        client_with_adapter(fn request ->
          {request, Req.Response.new(status: 200, body: %{"data" => [], "meta" => meta})}
        end)

      assert {:ok, %Page{data: [], meta: ^meta} = page} = Subscriptions.list(client)
      assert Page.next_cursor(page) == nil
    end

    test "surfaces transport exceptions unchanged" do
      client =
        client_with_adapter(fn request ->
          {request, %Req.TransportError{reason: :timeout}}
        end)

      assert {:error, %Req.TransportError{reason: :timeout}} = Subscriptions.list(client)
    end
  end

  describe "cancel/2" do
    test "issues POST /subscriptions/{id}/cancel with effective_from=next_billing_period and returns the updated subscription" do
      response_data = subscription_payload_active_with_scheduled_change()

      client =
        client_with_adapter(fn request ->
          assert request.method == :post
          assert request.url.path == "/subscriptions/sub_01/cancel"
          assert decode_json_body(request.body) == %{"effective_from" => "next_billing_period"}

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok,
              %Subscription{
                status: "active",
                scheduled_change: %ScheduledChange{
                  action: "cancel",
                  effective_at: "2024-05-12T10:37:59.556997Z",
                  resume_at: nil
                }
              }} = Subscriptions.cancel(client, "sub_01")
    end

    test "url-encodes subscription ids with reserved characters in the cancel path" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :post
          assert request.url.path == "/subscriptions/sub%2Fwith%3Freserved/cancel"

          {request,
           Req.Response.new(
             status: 200,
             body: %{"data" => subscription_payload_active_with_scheduled_change()}
           )}
        end)

      assert {:ok, %Subscription{}} = Subscriptions.cancel(client, "sub/with?reserved")
    end

    test "returns :invalid_subscription_id for nil/blank/whitespace/integer ids without dispatching HTTP" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      assert {:error, :invalid_subscription_id} = Subscriptions.cancel(client, nil)
      assert {:error, :invalid_subscription_id} = Subscriptions.cancel(client, "")
      assert {:error, :invalid_subscription_id} = Subscriptions.cancel(client, "   ")
      assert {:error, :invalid_subscription_id} = Subscriptions.cancel(client, 42)
    end

    test "preserves a 422 subscription_locked_pending_changes %Paddle.Error{} unchanged (Pitfall 6)" do
      client =
        client_with_adapter(fn request ->
          response =
            Req.Response.new(
              status: 422,
              body: %{
                "error" => %{
                  "type" => "request_error",
                  "code" => "subscription_locked_pending_changes",
                  "detail" => "Subscription is locked due to pending changes",
                  "errors" => []
                }
              }
            )
            |> Req.Response.put_header("x-request-id", "req_lock")

          {request, response}
        end)

      assert {:error,
              %Error{
                status_code: 422,
                request_id: "req_lock",
                type: "request_error",
                code: "subscription_locked_pending_changes",
                message: "Subscription is locked due to pending changes"
              }} = Subscriptions.cancel(client, "sub_01")
    end

    test "surfaces transport exceptions unchanged" do
      client =
        client_with_adapter(fn request ->
          {request, %Req.TransportError{reason: :timeout}}
        end)

      assert {:error, %Req.TransportError{reason: :timeout}} =
               Subscriptions.cancel(client, "sub_01")
    end
  end

  describe "cancel_immediately/2" do
    test "issues POST /subscriptions/{id}/cancel with effective_from=immediately and returns the canceled subscription with nil scheduled_change" do
      response_data = subscription_payload_canceled()

      client =
        client_with_adapter(fn request ->
          assert request.method == :post
          assert request.url.path == "/subscriptions/sub_01/cancel"
          assert decode_json_body(request.body) == %{"effective_from" => "immediately"}

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok,
              %Subscription{
                status: "canceled",
                scheduled_change: nil,
                management_urls: %ManagementUrls{}
              }} = Subscriptions.cancel_immediately(client, "sub_01")
    end

    test "url-encodes subscription ids with reserved characters in the cancel path" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :post
          assert request.url.path == "/subscriptions/sub%2Fwith%3Freserved/cancel"

          {request,
           Req.Response.new(status: 200, body: %{"data" => subscription_payload_canceled()})}
        end)

      assert {:ok, %Subscription{}} =
               Subscriptions.cancel_immediately(client, "sub/with?reserved")
    end

    test "returns :invalid_subscription_id for nil/blank/whitespace/integer ids without dispatching HTTP" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      assert {:error, :invalid_subscription_id} = Subscriptions.cancel_immediately(client, nil)
      assert {:error, :invalid_subscription_id} = Subscriptions.cancel_immediately(client, "")
      assert {:error, :invalid_subscription_id} = Subscriptions.cancel_immediately(client, "   ")
      assert {:error, :invalid_subscription_id} = Subscriptions.cancel_immediately(client, 42)
    end

    test "preserves a 404 entity_not_found %Paddle.Error{} unchanged" do
      client =
        client_with_adapter(fn request ->
          response =
            Req.Response.new(
              status: 404,
              body: %{
                "error" => %{
                  "type" => "request_error",
                  "code" => "entity_not_found",
                  "detail" => "Subscription not found",
                  "errors" => []
                }
              }
            )
            |> Req.Response.put_header("x-request-id", "req_404_ci")

          {request, response}
        end)

      assert {:error,
              %Error{
                status_code: 404,
                request_id: "req_404_ci",
                code: "entity_not_found",
                message: "Subscription not found"
              }} = Subscriptions.cancel_immediately(client, "sub_missing")
    end

    test "surfaces transport exceptions unchanged" do
      client =
        client_with_adapter(fn request ->
          {request, %Req.TransportError{reason: :timeout}}
        end)

      assert {:error, %Req.TransportError{reason: :timeout}} =
               Subscriptions.cancel_immediately(client, "sub_01")
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

  defp subscription_payload_canceled do
    %{
      "id" => "sub_01",
      "status" => "canceled",
      "customer_id" => "ctm_01",
      "address_id" => "add_01",
      "business_id" => nil,
      "currency_code" => "USD",
      "collection_mode" => "automatic",
      "custom_data" => nil,
      "items" => [],
      "scheduled_change" => nil,
      "management_urls" => %{
        "update_payment_method" =>
          "https://buyer-portal.paddle.com/subscriptions/sub_01/update-payment-method",
        "cancel" => "https://buyer-portal.paddle.com/subscriptions/sub_01/cancel"
      },
      "current_billing_period" => nil,
      "billing_cycle" => %{"frequency" => 1, "interval" => "month"},
      "billing_details" => nil,
      "discount" => nil,
      "next_billed_at" => nil,
      "started_at" => "2024-04-12T10:37:59.556997Z",
      "first_billed_at" => "2024-04-12T10:37:59.556997Z",
      "paused_at" => nil,
      "canceled_at" => "2024-04-12T11:24:54.868Z",
      "created_at" => "2024-04-12T10:38:00.761Z",
      "updated_at" => "2024-04-12T11:24:54.873Z",
      "import_meta" => nil
    }
  end

  defp subscription_payload_active_with_scheduled_change do
    Map.merge(subscription_payload_canceled(), %{
      "id" => "sub_01",
      "status" => "active",
      "canceled_at" => nil,
      "current_billing_period" => %{
        "starts_at" => "2024-04-12T10:37:59.556997Z",
        "ends_at" => "2024-05-12T10:37:59.556997Z"
      },
      "next_billed_at" => "2024-05-12T10:37:59.556997Z",
      "scheduled_change" => %{
        "action" => "cancel",
        "effective_at" => "2024-05-12T10:37:59.556997Z",
        "resume_at" => nil
      }
    })
  end

  defp subscription_payload_manual_no_payment_link do
    Map.merge(subscription_payload_canceled(), %{
      "collection_mode" => "manual",
      "management_urls" => %{
        "update_payment_method" => nil,
        "cancel" => "https://buyer-portal.paddle.com/subscriptions/sub_01/cancel"
      }
    })
  end
end
