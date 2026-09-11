# This test pins the full oarlock surface that Accrue targets.
# Scope: customer -> address -> transaction -> webhook -> subscription get -> pause -> resume -> cancel.
# Each step uses its own client because adapters are one-shot closures and must not be reused.
defmodule Paddle.SeamTest do
  use ExUnit.Case, async: false

  defmodule Adapter do
    def run(request) do
      request
      |> Req.Request.get_private(:paddle_test_adapter)
      |> then(& &1.(request))
    end
  end

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

  @documented_public_inventory %{
    Paddle.Customers => [create: 2, create: 3, get: 2, update: 3],
    Paddle.Customers.Addresses => [
      all: 2,
      all: 3,
      create: 3,
      create: 4,
      get: 3,
      list: 2,
      list: 3,
      stream: 2,
      stream: 3,
      update: 4
    ],
    Paddle.Customers.PortalSessions => [create: 2, create: 3, create: 4],
    Paddle.Transactions => [create: 2, create: 3, get: 2],
    Paddle.Adjustments => [
      all: 1,
      all: 2,
      create: 2,
      create: 3,
      get: 2,
      list: 1,
      list: 2,
      stream: 1,
      stream: 2
    ],
    Paddle.Subscriptions => [
      all: 1,
      all: 2,
      cancel: 2,
      cancel_immediately: 2,
      get: 2,
      list: 1,
      list: 2,
      pause: 2,
      pause: 3,
      pause_immediately: 2,
      pause_immediately: 3,
      resume: 2,
      resume: 3,
      stream: 1,
      stream: 2,
      update: 3
    ],
    Paddle.Webhooks => [parse_event: 1, verify_signature: 3, verify_signature: 4],
    Paddle.Products => [all: 1, all: 2, get: 2, list: 1, list: 2, stream: 1, stream: 2],
    Paddle.Prices => [all: 1, all: 2, get: 2, list: 1, list: 2, stream: 1, stream: 2],
    Paddle.Events => [all: 1, all: 2, get: 2, list: 1, list: 2, stream: 1, stream: 2],
    Paddle.NotificationSettings => [
      all: 1,
      all: 2,
      create: 2,
      create: 3,
      delete: 2,
      get: 2,
      list: 1,
      list: 2,
      stream: 1,
      stream: 2,
      update: 3
    ],
    Paddle.Page => [next_cursor: 1],
    Paddle.Error => [
      exception: 1,
      from_response: 1,
      from_response: 2,
      from_transport: 1,
      from_transport: 2,
      message: 1
    ],
    Paddle.PortalSessions => [create: 2]
  }

  @public_docs [
    "README.md",
    "guides/getting-started.md",
    "guides/accrue-seam.md",
    "demo/README.md",
    "CHANGELOG.md"
  ]

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

    assert {:ok,
            %Paddle.PortalSession{id: "pts_seam01", customer_id: "ctm_seam01"} = portal_session} =
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
        assert Req.Request.get_header(request, "idempotency-key") == []

        assert decode_json_body(request.body) == %{
                 "address_id" => "add_seam01",
                 "collection_mode" => "automatic",
                 "customer_id" => "ctm_seam01",
                 "items" => [%{"price_id" => "pri_seam01", "quantity" => 1}]
               }

        {request, Req.Response.new(status: 201, body: %{"data" => transaction_payload("ready")})}
      end)

    assert {:ok, %Transaction{id: "txn_seam01"} = transaction} =
             Paddle.Transactions.create(transaction_create_client,
               customer_id: customer.id,
               address_id: address.id,
               items: [%{price_id: "pri_seam01", quantity: 1}]
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

  test "adjustment and customer subresource mutation options stay inside the client trust boundary" do
    mutations = [
      %{
        call: fn client, opts ->
          Paddle.Adjustments.create(
            client,
            %{action: "refund", reason: "fraud", transaction_id: "txn_seam01"},
            opts
          )
        end,
        payload: adjustment_payload()
      },
      %{
        call: fn client, opts ->
          Paddle.Customers.Addresses.create(
            client,
            "ctm_seam01",
            %{country_code: "US", postal_code: "10001"},
            opts
          )
        end,
        payload: address_payload()
      },
      %{
        call: fn client, opts ->
          Paddle.Customers.PortalSessions.create(
            client,
            "ctm_seam01",
            %{subscription_ids: ["sub_seam01"]},
            opts
          )
        end,
        payload: portal_session_payload()
      }
    ]

    invalid_options = [
      "not-a-keyword",
      [retry: false, retry: true],
      [retry: :secret_retry_value],
      [base_url: "https://credential-canary.example"],
      [auth: {:bearer, "secret-auth-canary"}],
      [headers: [{"authorization", "secret-header-canary"}]],
      [adapter: {:secret_adapter_canary, []}]
    ]

    for %{call: call} <- mutations, opts <- invalid_options do
      {:ok, attempts} = Agent.start_link(fn -> 0 end)

      client =
        client_with_adapter(fn request ->
          Agent.update(attempts, &(&1 + 1))
          flunk("adapter received forbidden mutation options")
          {request, Req.Response.new(status: 201, body: %{})}
        end)

      error = assert_raise ArgumentError, fn -> call.(client, opts) end

      refute error.message =~ "credential-canary"
      refute error.message =~ "secret-auth-canary"
      refute error.message =~ "secret-header-canary"
      refute error.message =~ "secret_adapter_canary"
      refute error.message =~ "secret_retry_value"
      assert Agent.get(attempts, & &1) == 0
    end

    for %{call: call, payload: payload} <- mutations do
      {:ok, attempts} = Agent.start_link(fn -> 0 end)

      client =
        client_with_adapter(fn request ->
          Agent.update(attempts, &(&1 + 1))
          {request, Req.Response.new(status: 201, body: %{"data" => payload})}
        end)

      assert {:ok, _resource} = call.(client, retry: false)
      assert Agent.get(attempts, & &1) == 1
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
        "subscriptions" => [
          %{"id" => "sub_seam01", "cancel" => "https://buyer-portal.paddle.com/cancel/sub_seam01"}
        ]
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
      "totals" => %{
        "subtotal" => "1000",
        "tax" => "0",
        "total" => "1000",
        "fee" => "0",
        "earnings" => "1000"
      },
      "payouts" => %{
        "subtotal" => "1000",
        "tax" => "0",
        "total" => "1000",
        "fee" => "0",
        "earnings" => "1000"
      },
      "created_at" => "2024-04-12T10:38:00Z",
      "updated_at" => "2024-04-12T10:38:00Z"
    }
  end

  test "sealed modules remain undocumented" do
    for module <- [
          Paddle,
          Paddle.Application,
          Paddle.Internal.Attrs
        ] do
      assert {:docs_v1, _, _, _, :hidden, _, _} = Code.fetch_docs(module)
    end
  end

  test "public documentation pins the secure dependency and runtime migration contract" do
    readme = File.read!("README.md")
    getting_started = File.read!("guides/getting-started.md")
    telemetry = File.read!("guides/telemetry.md")
    seam = File.read!("guides/accrue-seam.md")
    changelog = File.read!("CHANGELOG.md")
    contract = Enum.join([readme, getting_started, telemetry, seam, changelog], "\n")

    for claim <- [
          "Req `~> 0.7.4`",
          "Elixir `~> 1.19`",
          "Elixir 1.19.5 / OTP 28.1",
          "three retries (four total attempts)",
          "408, 429, 500, 502, 503, and 504",
          "60,000 ms",
          "single attempt",
          "ambiguous",
          "`:lookup`, `:webhook`, and `:provider_dashboard`",
          "`[REDACTED]`"
        ] do
      assert contract =~ claim, "public contract is missing #{inspect(claim)}"
    end

    constructor_contract =
      readme |> markdown_section!("## Client Construction Contract") |> normalize_markdown()

    for row <- [
          "No environment and no base URL",
          "`:sandbox`",
          "`:live`",
          "`:custom`",
          "Noncanonical base URL only",
          "before Req construction"
        ] do
      assert constructor_contract =~ row
    end

    telemetry_contract =
      telemetry |> markdown_section!("## Request Events") |> normalize_markdown()

    for claim <- [
          "`:system_time`",
          "`:duration`",
          "`:method`",
          "`:host`",
          "`:attempt`",
          "`:operation`",
          "`:route`",
          "`:status`",
          "`:result`",
          "`:error_class`"
        ] do
      assert telemetry_contract =~ claim
    end

    for forbidden <- ["`:request`", "`:response`", "request.url"] do
      refute telemetry_contract =~ forbidden
    end

    refute Regex.match?(~r/idempotency_key:\s*["']|accepts? an? .*idempotency_key/i, contract)
    refute Regex.match?(~r/mutations? .*retr(?:y|ies) automatically/i, contract)
    refute Regex.match?(~r/https?:\/\/[^\s`]*@/i, contract)

    migration = changelog |> markdown_section!("### Phase 32 Migration") |> normalize_markdown()
    assert migration =~ "pre-1.0"
    assert migration =~ "removed `idempotency_key`"
    assert migration =~ "Telemetry metadata schema"
    assert migration =~ "constructor validation"
  end

  test "address stream documentation matches direct elements and raised enumeration failures" do
    docs =
      Paddle.Customers.Addresses
      |> function_doc!(:stream, 3)
      |> normalize_markdown()

    assert docs =~ "bare `%Paddle.Address{}` values"
    assert docs =~ "raises `%Paddle.Error{}` during enumeration"
    assert docs =~ "validation failures raise `ArgumentError` during enumeration"
    refute docs =~ "`{:ok, %Paddle.Address{}}`"
    refute docs =~ "`{:error, error}` elements"
  end

  test "compiled docs types and specs agree with the Phase 32 decision tables" do
    documented_modules = [
      Paddle.Client,
      Paddle.Http,
      Paddle.Error,
      Paddle.Internal.Pagination,
      Paddle.Adjustments,
      Paddle.Customers,
      Paddle.Customers.Addresses,
      Paddle.Customers.PortalSessions,
      Paddle.PortalSessions,
      Paddle.Events,
      Paddle.NotificationSettings,
      Paddle.Prices,
      Paddle.Products,
      Paddle.Subscriptions,
      Paddle.Transactions,
      Paddle.Http.Telemetry,
      Paddle.NotificationSetting,
      Paddle.PortalSession,
      Paddle.Subscription.ManagementUrls,
      Paddle.Transaction.Checkout
    ]

    for module <- documented_modules do
      assert {:docs_v1, _, _, _, docs, _, _} = Code.fetch_docs(module)
      refute docs == :hidden, "#{inspect(module)} must expose its Phase 32 contract"
    end

    assert normalized_moduledoc!(Paddle.Client) =~
             "unique options `:api_key`, `:environment`, and `:base_url`"

    assert normalized_moduledoc!(Paddle.Http) =~ "four physical attempts"
    assert normalized_moduledoc!(Paddle.Http) =~ "`:idempotency_key` is unsupported"
    assert normalized_moduledoc!(Paddle.Error) =~ "ambiguous and non-retryable"

    assert normalized_moduledoc!(Paddle.Internal.Pagination) =~
             "dynamic cursor path only as the dispatch URL"

    assert normalized_moduledoc!(Paddle.Http.Telemetry) =~ "exact payload schemas"

    for module <- [
          Paddle.Adjustments,
          Paddle.Customers,
          Paddle.Customers.Addresses,
          Paddle.Customers.PortalSessions,
          Paddle.NotificationSettings,
          Paddle.Subscriptions,
          Paddle.Transactions
        ] do
      {:ok, types} = Code.Typespec.fetch_types(module)
      assert term_contains_atom?(types, :retry)
      refute term_contains_atom?(types, :idempotency_key)
    end

    assert spec_arities(Paddle.Client) == [new!: 1]
    assert {:request, 4} in spec_arities(Paddle.Http)
    assert {:next_page, 4} in spec_arities(Paddle.Internal.Pagination)
    refute {:next_page, 3} in Paddle.Internal.Pagination.__info__(:functions)
    assert {:attach, 1} in spec_arities(Paddle.Http.Telemetry)

    for module <- [
          Paddle.NotificationSetting,
          Paddle.PortalSession,
          Paddle.Subscription.ManagementUrls,
          Paddle.Transaction.Checkout
        ] do
      assert normalized_moduledoc!(module) =~ "[REDACTED]"
    end
  end

  test "seam guide documents the live public inventory and portal compatibility boundary" do
    seam_guide = File.read!("guides/accrue-seam.md")

    for {module, expected_functions} <- @documented_public_inventory do
      actual_functions =
        module.__info__(:functions)
        |> Keyword.drop([:__struct__])
        |> Enum.sort()

      assert actual_functions == Enum.sort(expected_functions)
      assert seam_guide =~ inspect(module)

      for {function, arity} <- expected_functions do
        assert seam_guide =~ "#{function}/#{arity}",
               "#{inspect(module)}.#{function}/#{arity} is exported but missing from the seam guide"
      end
    end

    assert seam_guide =~ "Paddle.Customers.PortalSessions.create/4"
    assert seam_guide =~ "preferred customer portal seam"
    assert seam_guide =~ "Paddle.PortalSessions.create/2"
    assert seam_guide =~ "compatibility"
  end

  test "demo runbook documents local setup, mock auth, handoffs, proof boundary, and live checklist" do
    demo_readme = File.read!("demo/README.md")

    intro = demo_readme |> markdown_section!("# oarlock Phoenix Demo") |> normalize_markdown()

    demonstrated =
      demo_readme |> markdown_section!("## What It Demonstrates") |> normalize_markdown()

    run_locally = demo_readme |> markdown_section!("## Run Locally") |> normalize_markdown()

    offline_mode =
      demo_readme |> markdown_section!("## Offline Paddle Mode") |> normalize_markdown()

    webhook_flow = demo_readme |> markdown_section!("## Webhook Flow") |> normalize_markdown()

    handoffs =
      demo_readme |> markdown_section!("## Checkout and Portal Handoffs") |> normalize_markdown()

    before_live = demo_readme |> markdown_section!("## Before Live Mode") |> normalize_markdown()

    assert intro =~ "sign in as the mock merchant"
    assert intro =~ "demo app code versus oarlock SDK code"
    assert demonstrated =~ "Mock authentication"
    assert demonstrated =~ "Paddle.Transactions.create/3"
    assert demonstrated =~ "Raw-body webhook verification"
    assert demonstrated =~ "Customer portal handoff"
    assert demonstrated =~ "Offline development against `Paddle.MockServer`"
    assert demonstrated =~ "The demo owns users, database tables, PubSub updates, and UI state"
    assert demonstrated =~ "oarlock only owns the Paddle client seam"
    assert demonstrated =~ "fixed demo merchant"

    assert run_locally =~ "cd demo"
    assert run_locally =~ "mix setup"
    assert run_locally =~ "mix phx.server"
    assert run_locally =~ "http://localhost:4000/login"
    assert run_locally =~ "http://localhost:4000/admin"

    assert webhook_flow =~ "verifies the exact raw request body before it trusts an event"
    assert webhook_flow =~ "stores the event and updates local subscription state"
    assert webhook_flow =~ "DemoWeb.WebhookSimulator"
    assert webhook_flow =~ "raw-body verification boundary"

    assert handoffs =~ "MockServer checkout URL"
    assert handoffs =~ "`open_checkout`"
    assert handoffs =~ "`Manage billing`"
    assert handoffs =~ "creates a Paddle portal session"
    assert handoffs =~ "Paddle-hosted URL"
    assert handoffs =~ "operational handoff"

    assert offline_mode =~ "Paddle.MockServer"
    assert offline_mode =~ "development fixture, not a complete Paddle clone"
    assert offline_mode =~ "deterministic local SDK/demo wiring"
    assert offline_mode =~ "real Paddle sandbox credentials"
    assert offline_mode =~ "operator-owned readiness"
    assert offline_mode =~ "not live Paddle provider-state verification"

    for checklist_item <- [
          "Configure real Paddle price IDs",
          "Complete a sandbox checkout using real sandbox credentials",
          "Configure the Paddle webhook destination and endpoint secret",
          "Verify the exact raw request body before parsing or trusting events",
          "Make webhook handling idempotent",
          "Keep sandbox and live credentials, secrets, and price IDs separated",
          "final live credential swap as an operator-owned release step"
        ] do
      assert before_live =~ checklist_item
    end
  end

  test "first-read docs preserve app-owned boundaries and the supported adopter journey" do
    readme = "README.md" |> File.read!() |> normalize_markdown()
    getting_started = "guides/getting-started.md" |> File.read!() |> normalize_markdown()

    assert readme =~ "explicit `%Paddle.Client{}` passing"
    assert readme =~ "customer -> address -> transaction -> checkout -> webhook -> subscription"
    assert readme =~ "Create a transaction and hand the hosted checkout URL to a browser"
    assert readme =~ "verify the raw body before you trust it"
    assert readme =~ "Paddle.Webhooks.verify_signature(raw_body, signature_header, secret)"
    assert readme =~ "Paddle.Webhooks.parse_event(raw_body)"
    assert readme =~ "Your app owns users, accounts, provisioning, entitlements, and persistence"
    assert readme =~ "A Phoenix or Plug integration package"
    assert readme =~ "An Ecto schema or database sync layer"
    assert readme =~ "A billing UI or customer portal replacement"

    assert getting_started =~ "Create or look up a Paddle customer"
    assert getting_started =~ "Attach a billing address"
    assert getting_started =~ "Create a transaction for the price you want to sell"
    assert getting_started =~ "Send the user to Paddle Checkout"
    assert getting_started =~ "Verify the webhook when Paddle tells you payment completed"
    assert getting_started =~ "Save the resulting Paddle IDs and grant access in your app"

    assert getting_started =~
             "Paddle.Webhooks.verify_signature(raw_body, signature_header, secret)"

    assert getting_started =~ "Paddle.Webhooks.parse_event(raw_body)"
    assert getting_started =~ "Paddle.Subscriptions.get(client, transaction.subscription_id)"
    assert getting_started =~ "Paddle.Customers.PortalSessions.create/4"

    assert getting_started =~
             "Your app still owns authorization, audit records, and local state updates"

    assert getting_started =~ "Phoenix request parsing or webhook plugs"
    assert getting_started =~ "Ecto schemas or synchronization tables"

    assert getting_started =~
             "Durable app-owned purchase intents and reconciliation status for mutation jobs"

    assert getting_started =~
             "verifies the exact raw request body before parsing or trusting events"
  end

  test "public docs do not claim provider-state proof from local fixtures" do
    unsupported_claims = [
      ~r/\bsandbox verified\b/i,
      ~r/\bprovider-state verified\b/i,
      ~r/\blive verified\b/i
    ]

    for path <- @public_docs do
      body = File.read!(path)

      for claim <- unsupported_claims do
        refute Regex.match?(claim, body),
               "#{path} contains unsupported provider proof wording matching #{inspect(claim)}"
      end
    end

    assert Enum.any?(@public_docs, fn path ->
             File.read!(path) =~ "MockServer"
           end)
  end

  test "public proof ladders keep every evidence tier and authority boundary distinct" do
    for path <- [
          "README.md",
          "guides/getting-started.md",
          "guides/accrue-seam.md",
          "demo/README.md"
        ] do
      proof =
        path |> File.read!() |> markdown_section!("## Proof Boundary") |> normalize_markdown()

      for tier <- [
            "Unit and contract tests",
            "Paddle.MockServer",
            "Package and downstream consumer checks",
            "Paddle sandbox",
            "Hosted CI",
            "Live provider"
          ] do
        assert proof =~ tier, "#{path} proof ladder is missing #{tier}"
      end

      for unsupported <- [
            ~r/MockServer .*proves? (?:Paddle |live )?provider/i,
            ~r/package .*proves? live/i,
            ~r/header .*proves? (?:provider )?(?:deduplication|idempotency)/i,
            ~r/hosted CI .*proves? live provider/i
          ] do
        refute Regex.match?(unsupported, proof),
               "#{path} inflates evidence with #{inspect(unsupported)}"
      end
    end

    proof_script = File.read!("bin/phase32_contract_proof.sh")

    for marker <- [
          "phase32_compatibility.sh",
          "MIX_BUILD_PATH",
          "phase32-compatibility.receipt",
          "SAFE-01",
          "SAFE-02",
          "SAFE-03",
          "SAFE-04",
          "SAFE-05",
          "SAFE-06"
        ] do
      assert proof_script =~ marker
    end
  end

  test "Phase 32 proof runners separate bounded verification from full acceptance" do
    compatibility = File.read!("bin/phase32_compatibility.sh")
    contract = File.read!("bin/phase32_contract_proof.sh")

    for marker <- ["--verify", "--full", "phase32-verifier.receipt", "mix hex.audit"] do
      assert compatibility =~ marker
    end

    for row <- [
          "root-suite",
          "focused-http-adapter",
          "focused-customer-adapters",
          "focused-catalog-adapters",
          "focused-subscription-transaction-seam-adapters",
          "telemetry-adapter",
          "mockserver-subscription-flows",
          "dialyzer",
          "docs",
          "package-smoke-without-optional-deps",
          "demo-precommit",
          "downstream-accrue-seam",
          "online-hex-audit"
        ] do
      assert compatibility =~ ~s(run_row "#{row}")
    end

    for marker <- [
          "--verify",
          "--full",
          "phase32-contract-verifier.receipt",
          "phase32-verifier.receipt",
          "canonical_receipt_manifest"
        ] do
      assert contract =~ marker
    end

    assert length(Regex.scan(~r/phase32_compatibility\.sh" --full/, contract)) == 2
    assert compatibility =~ "bounded verifier evidence"
    assert compatibility =~ "full 13-row D-03 acceptance"
    assert contract =~ "bounded verifier evidence"
    assert contract =~ "full D-03 acceptance"

    for script <- [compatibility, contract],
        unsupported <- ["hosted authority", "release authority", "publication authority"] do
      refute script =~ "claims #{unsupported}"
    end
  end

  test "Phase 32 full receipt invalidation precedes every Accrue preflight" do
    compatibility = File.read!("bin/phase32_compatibility.sh")

    for marker <- [
          "preflight-missing",
          "preflight-invalid",
          "run_matrix_preflight",
          "invalidate_full_receipt"
        ] do
      assert compatibility =~ marker
    end

    {invalidate_at, _} = :binary.match(compatibility, "invalidate_full_receipt")
    {preflight_at, _} = :binary.match(compatibility, "ACCRUE_CHECKOUT is required")
    assert invalidate_at < preflight_at
  end

  defp markdown_section!(markdown, heading) do
    pattern = Regex.compile!("^#{Regex.escape(heading)}\\n(?<body>.*?)(?=^## |\\z)", "ms")

    case Regex.named_captures(pattern, markdown) do
      %{"body" => body} -> body
      _ -> flunk("#{heading} section is missing from demo/README.md")
    end
  end

  defp normalize_markdown(markdown) do
    Regex.replace(~r/\s+/, markdown, " ")
  end

  defp moduledoc!(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, %{"en" => moduledoc}, _, _} ->
        moduledoc

      other ->
        flunk("expected English module docs for #{inspect(module)}, got: #{inspect(other)}")
    end
  end

  defp normalized_moduledoc!(module), do: module |> moduledoc!() |> normalize_markdown()

  defp function_doc!(module, name, arity) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, _, docs} ->
        case Enum.find(docs, fn {{kind, doc_name, doc_arity}, _, _, _, _} ->
               kind == :function and doc_name == name and doc_arity == arity
             end) do
          {{:function, ^name, ^arity}, _, _, %{"en" => doc}, _} ->
            doc

          other ->
            flunk(
              "expected English docs for #{inspect(module)}.#{name}/#{arity}, got: #{inspect(other)}"
            )
        end

      other ->
        flunk("expected compiled docs for #{inspect(module)}, got: #{inspect(other)}")
    end
  end

  defp spec_arities(module) do
    {:ok, specs} = Code.Typespec.fetch_specs(module)
    specs |> Enum.map(fn {{name, arity}, _specs} -> {name, arity} end) |> Enum.sort()
  end

  defp term_contains_atom?(term, atom) when is_atom(term), do: term == atom

  defp term_contains_atom?(term, atom) when is_tuple(term) do
    term |> Tuple.to_list() |> Enum.any?(&term_contains_atom?(&1, atom))
  end

  defp term_contains_atom?(term, atom) when is_list(term) do
    Enum.any?(term, &term_contains_atom?(&1, atom))
  end

  defp term_contains_atom?(_term, _atom), do: false
end
