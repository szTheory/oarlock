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

    test "normalizes transport exceptions into Paddle.Error" do
      client =
        client_with_adapter(fn request ->
          {request, %Req.TransportError{reason: :timeout}}
        end)

      assert {:error, %Error{type: "network_timeout", network_error?: true, retryable?: true}} =
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

    test "normalizes transport exceptions into Paddle.Error" do
      client =
        client_with_adapter(fn request ->
          {request, %Req.TransportError{reason: :timeout}}
        end)

      assert {:error, %Error{type: "network_timeout", network_error?: true, retryable?: true}} =
               Subscriptions.list(client)
    end
  end

  describe "stream/2" do
    test "streams subscriptions across three pages in order and replays Paddle next URLs" do
      {client, requests} = client_with_get_sequence(subscription_pagination_requests())

      subscriptions =
        client
        |> Subscriptions.stream(status: "active")
        |> Enum.to_list()

      assert Enum.map(subscriptions, & &1.id) == ["sub_01", "sub_02", "sub_03"]
      assert Enum.all?(subscriptions, &match?(%Subscription{}, &1))
      assert_no_more_requests(requests)
    end

    test "raises Paddle.Error when a later page fails" do
      {client, _requests} =
        client_with_get_sequence([
          %{
            path: "/subscriptions",
            query: %{},
            response: subscription_page(["sub_01"], true, "/subscriptions?after=cursor_1")
          },
          %{
            path: "/subscriptions",
            query: %{"after" => "cursor_1"},
            response: paddle_unavailable_response()
          }
        ])

      error =
        assert_raise Error, fn ->
          client
          |> Subscriptions.stream()
          |> Enum.to_list()
        end

      assert error.status_code == 503
      assert error.message == "Paddle unavailable"
    end

    test "raises ArgumentError for invalid initial params during enumeration" do
      client =
        client_with_adapter(fn request -> flunk("unexpected request: #{inspect(request)}") end)

      stream = Subscriptions.stream(client, "nope")

      assert_raise ArgumentError, ~r/:invalid_params/, fn ->
        Enum.to_list(stream)
      end
    end

    test "fetches only the first page when the consumer stops early" do
      {client, requests} =
        client_with_get_sequence([
          %{
            path: "/subscriptions",
            query: %{},
            response: subscription_page(["sub_01"], true, "/subscriptions?after=cursor_1")
          }
        ])

      assert [%Subscription{id: "sub_01"}] =
               client
               |> Subscriptions.stream()
               |> Enum.take(1)

      assert_no_more_requests(requests)
    end
  end

  describe "all/2" do
    test "returns the same ordered subscriptions as stream/2" do
      {stream_client, stream_requests} =
        client_with_get_sequence(subscription_pagination_requests())

      stream_ids =
        stream_client
        |> Subscriptions.stream(status: "active")
        |> Enum.map(& &1.id)

      assert_no_more_requests(stream_requests)

      {all_client, all_requests} = client_with_get_sequence(subscription_pagination_requests())

      assert {:ok, subscriptions} = Subscriptions.all(all_client, status: "active")
      assert Enum.map(subscriptions, & &1.id) == stream_ids
      assert_no_more_requests(all_requests)
    end

    test "returns the first later-page Paddle.Error without partial results" do
      {client, _requests} =
        client_with_get_sequence([
          %{
            path: "/subscriptions",
            query: %{},
            response: subscription_page(["sub_01"], true, "/subscriptions?after=cursor_1")
          },
          %{
            path: "/subscriptions",
            query: %{"after" => "cursor_1"},
            response: paddle_unavailable_response()
          }
        ])

      assert {:error, %Error{status_code: 503, message: "Paddle unavailable"}} =
               Subscriptions.all(client)
    end

    test "returns validation atoms from the initial list call" do
      client =
        client_with_adapter(fn request -> flunk("unexpected request: #{inspect(request)}") end)

      assert {:error, :invalid_params} = Subscriptions.all(client, "nope")
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

    test "normalizes transport exceptions into Paddle.Error" do
      client =
        client_with_adapter(fn request ->
          {request, %Req.TransportError{reason: :timeout}}
        end)

      assert {:error, %Error{type: "network_timeout", network_error?: true, retryable?: true}} =
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

    test "normalizes transport exceptions into Paddle.Error" do
      client =
        client_with_adapter(fn request ->
          {request, %Req.TransportError{reason: :timeout}}
        end)

      assert {:error, %Error{type: "network_timeout", network_error?: true, retryable?: true}} =
               Subscriptions.cancel_immediately(client, "sub_01")
    end
  end

  describe "pause/3" do
    test "issues POST /subscriptions/{id}/pause with effective_from=next_billing_period and returns typed hydration" do
      response_data = subscription_payload_active_with_scheduled_pause()

      client =
        client_with_adapter(fn request ->
          assert request.method == :post
          assert request.url.path == "/subscriptions/sub_01/pause"

          assert decode_json_body(request.body) == %{
                   "effective_from" => "next_billing_period",
                   "resume_at" => "2026-07-01T00:00:00Z",
                   "on_resume" => "start_new_billing_period"
                 }

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok, %Subscription{status: "active"} = subscription} =
               Subscriptions.pause(client, "sub_01",
                 resume_at: "2026-07-01T00:00:00Z",
                 on_resume: :start_new_billing_period
               )

      assert %ScheduledChange{action: "pause", resume_at: "2026-07-01T00:00:00Z"} =
               subscription.scheduled_change

      assert %ManagementUrls{} = subscription.management_urls
    end

    test "encodes DateTime resume_at values as RFC3339 and accepts on_resume provider strings" do
      response_data = subscription_payload_active_with_scheduled_pause()

      client =
        client_with_adapter(fn request ->
          assert decode_json_body(request.body) == %{
                   "effective_from" => "next_billing_period",
                   "resume_at" => "2026-07-01T00:00:00Z",
                   "on_resume" => "continue_existing_billing_period"
                 }

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok, %Subscription{}} =
               Subscriptions.pause(client, "sub_01",
                 resume_at: ~U[2026-07-01 00:00:00Z],
                 on_resume: "continue_existing_billing_period"
               )
    end

    test "returns :invalid_subscription_id for invalid ids without dispatching HTTP" do
      client =
        client_with_adapter(fn request ->
          flunk("unexpected request: #{inspect(request)}")
        end)

      assert {:error, :invalid_subscription_id} = Subscriptions.pause(client, nil)
      assert {:error, :invalid_subscription_id} = Subscriptions.pause(client, "")
      assert {:error, :invalid_subscription_id} = Subscriptions.pause(client, "   ")
      assert {:error, :invalid_subscription_id} = Subscriptions.pause(client, 42)
    end

    test "returns local validation errors for invalid resume_at and on_resume values" do
      client =
        client_with_adapter(fn request ->
          flunk("unexpected request: #{inspect(request)}")
        end)

      assert {:error, :invalid_resume_at} =
               Subscriptions.pause(client, "sub_01", resume_at: "not-rfc3339")

      assert {:error, :invalid_on_resume} =
               Subscriptions.pause(client, "sub_01", on_resume: :not_allowed)
    end

    test "raises ArgumentError for idempotency_key and unsupported keys before dispatch" do
      client =
        client_with_adapter(fn request ->
          flunk("unexpected request: #{inspect(request)}")
        end)

      assert_raise ArgumentError, ~r/idempotency_key is not supported for pause operations/, fn ->
        Subscriptions.pause(client, "sub_01", idempotency_key: "attempt-1")
      end

      assert_raise ArgumentError, ~r/unknown pause option/, fn ->
        Subscriptions.pause(client, "sub_01", unknown_pause_option: true)
      end
    end

    test "per-call retry: false disables retry on 503 pause responses" do
      {:ok, attempts} = Agent.start_link(fn -> 0 end)

      client =
        client_with_retry_adapter(fn request ->
          Agent.update(attempts, &(&1 + 1))
          assert request.url.path == "/subscriptions/sub_01/pause"
          {request, Req.Response.new(status: 503, body: %{})}
        end)

      assert {:error, %Error{status_code: 503}} =
               Subscriptions.pause(client, "sub_01", retry: false)

      assert Agent.get(attempts, & &1) == 1
      Agent.stop(attempts)
    end
  end

  describe "pause_immediately/3" do
    test "issues POST /subscriptions/{id}/pause with effective_from=immediately" do
      response_data = subscription_payload_active_with_scheduled_pause()

      client =
        client_with_adapter(fn request ->
          assert request.method == :post
          assert request.url.path == "/subscriptions/sub_01/pause"

          assert decode_json_body(request.body) == %{
                   "effective_from" => "immediately",
                   "resume_at" => "2026-07-01T00:00:00Z",
                   "on_resume" => "start_new_billing_period"
                 }

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok, %Subscription{status: "active"}} =
               Subscriptions.pause_immediately(client, "sub_01",
                 resume_at: ~U[2026-07-01 00:00:00Z],
                 on_resume: "start_new_billing_period"
               )
    end

    test "raises ArgumentError for idempotency_key" do
      client =
        client_with_adapter(fn request ->
          flunk("unexpected request: #{inspect(request)}")
        end)

      assert_raise ArgumentError, ~r/idempotency_key/, fn ->
        Subscriptions.pause_immediately(client, "sub_01", idempotency_key: "attempt-2")
      end
    end
  end

  describe "resume/3" do
    test "issues POST /subscriptions/{id}/resume and defaults effective_from to immediately" do
      response_data = subscription_payload_active_with_scheduled_change()

      client =
        client_with_adapter(fn request ->
          assert request.method == :post
          assert request.url.path == "/subscriptions/sub_01/resume"

          assert decode_json_body(request.body) == %{
                   "effective_from" => "immediately",
                   "on_resume" => "start_new_billing_period"
                 }

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok, %Subscription{status: "active"}} =
               Subscriptions.resume(client, "sub_01", on_resume: :start_new_billing_period)
    end

    test "accepts effective_from DateTime and RFC3339 values and on_resume provider strings" do
      response_data = subscription_payload_active_with_scheduled_change()

      client =
        client_with_adapter(fn request ->
          assert decode_json_body(request.body) == %{
                   "effective_from" => "2026-07-01T00:00:00Z",
                   "on_resume" => "continue_existing_billing_period"
                 }

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok, %Subscription{}} =
               Subscriptions.resume(client, "sub_01",
                 effective_from: ~U[2026-07-01 00:00:00Z],
                 on_resume: "continue_existing_billing_period"
               )
    end

    test "returns local validation errors for invalid effective_from and on_resume values" do
      client =
        client_with_adapter(fn request ->
          flunk("unexpected request: #{inspect(request)}")
        end)

      assert {:error, :invalid_effective_from} =
               Subscriptions.resume(client, "sub_01", effective_from: :not_allowed)

      assert {:error, :invalid_on_resume} =
               Subscriptions.resume(client, "sub_01", on_resume: :not_allowed)
    end

    test "raises ArgumentError for idempotency_key and unsupported keys before dispatch" do
      client =
        client_with_adapter(fn request ->
          flunk("unexpected request: #{inspect(request)}")
        end)

      assert_raise ArgumentError,
                   ~r/idempotency_key is not supported for resume operations/,
                   fn ->
                     Subscriptions.resume(client, "sub_01", idempotency_key: "attempt-3")
                   end

      assert_raise ArgumentError, ~r/unknown resume option/, fn ->
        Subscriptions.resume(client, "sub_01", unknown_resume_option: true)
      end
    end

    test "per-call retry: false disables retry on 422 resume responses and preserves provider errors" do
      {:ok, attempts} = Agent.start_link(fn -> 0 end)

      client =
        client_with_retry_adapter(fn request ->
          Agent.update(attempts, &(&1 + 1))
          assert request.url.path == "/subscriptions/sub_01/resume"

          response =
            Req.Response.new(
              status: 422,
              body: %{
                "error" => %{
                  "type" => "request_error",
                  "code" => "subscription_missing_payment_method_cannot_resume",
                  "detail" => "Cannot resume subscription without a payment method",
                  "errors" => []
                }
              }
            )
            |> Req.Response.put_header("x-request-id", "req_resume_422")

          {request, response}
        end)

      assert {:error,
              %Error{
                status_code: 422,
                request_id: "req_resume_422",
                code: "subscription_missing_payment_method_cannot_resume",
                message: "Cannot resume subscription without a payment method"
              }} =
               Subscriptions.resume(client, "sub_01", retry: false)

      assert Agent.get(attempts, & &1) == 1
      Agent.stop(attempts)
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

  defp client_with_retry_adapter(adapter) do
    %Client{
      api_key: "sk_test_123",
      environment: :sandbox,
      req:
        Req.new(
          base_url: "https://sandbox-api.paddle.com",
          retry: :transient,
          retry_delay: fn _ -> 0 end,
          max_retries: 3,
          adapter: adapter
        )
    }
  end

  defp client_with_get_sequence(expected_requests) do
    {:ok, requests} = Agent.start_link(fn -> expected_requests end)

    client =
      client_with_adapter(fn request ->
        expected =
          Agent.get_and_update(requests, fn
            [expected | rest] ->
              {expected, rest}

            [] ->
              flunk("unexpected request: #{request.method} #{URI.to_string(request.url)}")
          end)

        assert request.method == :get
        assert request.url.path == expected.path
        assert URI.decode_query(request.url.query || "") == expected.query
        assert request.body == nil

        {request, expected.response}
      end)

    {client, requests}
  end

  defp assert_no_more_requests(requests) do
    assert Agent.get(requests, & &1) == []
  end

  defp subscription_pagination_requests do
    [
      %{
        path: "/subscriptions",
        query: %{"status" => "active"},
        response:
          subscription_page(
            ["sub_01"],
            true,
            "https://api.paddle.com/subscriptions?status=active&after=cursor_1"
          )
      },
      %{
        path: "/subscriptions",
        query: %{"status" => "active", "after" => "cursor_1"},
        response:
          subscription_page(
            ["sub_02"],
            true,
            "/subscriptions?status=active&after=cursor_2"
          )
      },
      %{
        path: "/subscriptions",
        query: %{"status" => "active", "after" => "cursor_2"},
        response:
          subscription_page(
            ["sub_03"],
            false,
            "/subscriptions?status=active&after=cursor_3"
          )
      }
    ]
  end

  defp subscription_page(ids, has_more, next) do
    Req.Response.new(
      status: 200,
      body: %{
        "data" => Enum.map(ids, &subscription_payload/1),
        "meta" => %{
          "pagination" => %{
            "per_page" => 1,
            "next" => next,
            "has_more" => has_more,
            "estimated_total" => 3
          }
        }
      }
    )
  end

  defp subscription_payload(id) do
    Map.put(subscription_payload_active_with_scheduled_change(), "id", id)
  end

  defp paddle_unavailable_response do
    Req.Response.new(
      status: 503,
      body: %{
        "error" => %{
          "type" => "request_error",
          "code" => "service_unavailable",
          "detail" => "Paddle unavailable",
          "errors" => []
        }
      }
    )
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

  defp subscription_payload_active_with_scheduled_pause do
    Map.merge(subscription_payload_active_with_scheduled_change(), %{
      "scheduled_change" => %{
        "action" => "pause",
        "effective_at" => "2026-06-10T10:37:59.556997Z",
        "resume_at" => "2026-07-01T00:00:00Z"
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
