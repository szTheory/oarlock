defmodule Paddle.NotificationSettingsTest do
  use ExUnit.Case, async: true

  defmodule Adapter do
    def run(request) do
      request
      |> Req.Request.get_private(:paddle_test_adapter)
      |> then(& &1.(request))
    end
  end

  alias Paddle.Client
  alias Paddle.Error
  alias Paddle.NotificationSetting
  alias Paddle.NotificationSettings

  describe "create/3" do
    test "returns {:error, :missing_api_version} if api_version is omitted" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      attrs = %{description: "Test Webhook", destination: "https://example.com/hooks"}
      assert {:error, :missing_api_version} = NotificationSettings.create(client, attrs)
    end

    test "sends POST request with filtered JSON payload and returns %NotificationSetting{}" do
      response_data = setting_payload()

      client =
        client_with_adapter(fn request ->
          assert request.method == :post
          assert request.url.path == "/notification-settings"
          assert request_context(request) == create_request_context()

          # Notice api_version, type, destination, etc., and dropped extra_field
          assert Jason.decode!(IO.iodata_to_binary(request.body)) ==
                   %{
                     "description" => "Test",
                     "destination" => "https://example.com/hooks",
                     "type" => "url",
                     "api_version" => 1,
                     "active" => true
                   }

          {request, Req.Response.new(status: 201, body: %{"data" => response_data})}
        end)

      attrs = %{
        description: "Test",
        destination: "https://example.com/hooks",
        type: "url",
        api_version: 1,
        active: true,
        extra_field: "should be dropped"
      }

      assert {:ok, %NotificationSetting{id: "ntfset_01", raw_data: ^response_data}} =
               NotificationSettings.create(client, attrs)
    end

    test "non-2xx API error maps to %Error{}" do
      client =
        client_with_adapter(fn request ->
          error_body = %{
            "error" => %{
              "type" => "request_error",
              "code" => "bad_request",
              "detail" => "Invalid URL"
            }
          }

          {request, Req.Response.new(status: 400, body: error_body)}
        end)

      attrs = %{api_version: 1, destination: "not-a-url"}

      assert {:error, %Paddle.Error{code: "bad_request"}} =
               NotificationSettings.create(client, attrs)
    end

    test "makes one attempt and exposes secret-safe ambiguity without idempotency support" do
      {:ok, attempts} = Agent.start_link(fn -> 0 end)

      client =
        client_with_adapter(fn request ->
          Agent.update(attempts, &(&1 + 1))
          {request, %Req.TransportError{reason: :timeout}}
        end)

      assert {:error,
              %Error{
                ambiguous?: true,
                retryable?: false,
                operation: :create_notification_setting,
                resource_id: nil,
                reconciliation: [:lookup, :webhook, :provider_dashboard]
              }} =
               NotificationSettings.create(client, %{
                 api_version: 1,
                 destination: "https://secret.example/hooks"
               })

      assert Agent.get(attempts, & &1) == 1

      assert_raise ArgumentError, ~r/idempotency_key is not supported/, fn ->
        NotificationSettings.create(client, %{api_version: 1}, idempotency_key: "idem_forbidden")
      end

      assert Agent.get(attempts, & &1) == 1
    end

    test "rejects malformed and transport-authority options before dispatch" do
      assert_public_mutation_option_contract(
        fn client, opts ->
          NotificationSettings.create(
            client,
            %{api_version: 1, destination: "https://notification.example/hooks"},
            opts
          )
        end,
        setting_payload()
      )
    end
  end

  describe "update/3" do
    test "sends PATCH request to /notification-settings/:id with filtered JSON payload" do
      response_data = %{setting_payload() | "active" => false}

      client =
        client_with_adapter(fn request ->
          assert request.method == :patch
          assert request.url.path == "/notification-settings/ntfset_01"
          assert request_context(request) == update_request_context("ntfset_01")

          assert Jason.decode!(IO.iodata_to_binary(request.body)) == %{"active" => false}

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      attrs = %{
        active: false,
        extra_field: "should be dropped",
        # allowed in create but not update, should be dropped
        api_version: 1
      }

      assert {:ok, %NotificationSetting{id: "ntfset_01", active: false}} =
               NotificationSettings.update(client, "ntfset_01", attrs)
    end

    test "returns error for blank id" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      assert {:error, :invalid_notification_setting_id} =
               NotificationSettings.update(client, "", %{})
    end

    test "makes one attempt and exposes only the setting ID in ambiguity context" do
      {:ok, attempts} = Agent.start_link(fn -> 0 end)

      client =
        client_with_adapter(fn request ->
          Agent.update(attempts, &(&1 + 1))
          {request, Req.Response.new(status: 503, body: %{})}
        end)

      assert {:error,
              %Error{
                ambiguous?: true,
                retryable?: false,
                operation: :update_notification_setting,
                resource_id: "ntfset_runtime_secret",
                reconciliation: [:lookup, :webhook, :provider_dashboard]
              }} =
               NotificationSettings.update(client, "ntfset_runtime_secret", %{active: false})

      assert Agent.get(attempts, & &1) == 1
    end
  end

  describe "delete/2" do
    test "sends DELETE request to /notification-settings/:id and returns :ok" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :delete
          assert request.url.path == "/notification-settings/ntfset_01"
          assert request_context(request) == delete_request_context("ntfset_01")

          {request, Req.Response.new(status: 200, body: %{})}
        end)

      assert :ok = NotificationSettings.delete(client, "ntfset_01")
    end

    test "returns error for blank id" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{})})
      assert {:error, :invalid_notification_setting_id} = NotificationSettings.delete(client, "")
    end

    test "makes one attempt and returns ambiguity guidance for transport failure" do
      {:ok, attempts} = Agent.start_link(fn -> 0 end)

      client =
        client_with_adapter(fn request ->
          Agent.update(attempts, &(&1 + 1))
          {request, %Req.TransportError{reason: :closed}}
        end)

      assert {:error,
              %Error{
                ambiguous?: true,
                retryable?: false,
                operation: :delete_notification_setting,
                resource_id: "ntfset_01",
                reconciliation: [:lookup, :webhook, :provider_dashboard]
              }} = NotificationSettings.delete(client, "ntfset_01")

      assert Agent.get(attempts, & &1) == 1
    end
  end

  describe "get/2" do
    test "requests the notification setting path with explicit client passing and returns a typed struct" do
      response_data = setting_payload()

      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/notification-settings/ntfset_01"
          assert request.body == nil
          assert request_context(request) == get_request_context()

          {request, Req.Response.new(status: 200, body: %{"data" => response_data})}
        end)

      assert {:ok, %NotificationSetting{id: "ntfset_01", raw_data: ^response_data}} =
               NotificationSettings.get(client, "ntfset_01")
    end

    test "returns an explicit error for blank notification setting ids" do
      client = client_with_adapter(&{&1, Req.Response.new(status: 200, body: %{"data" => %{}})})

      assert {:error, :invalid_notification_setting_id} = NotificationSettings.get(client, nil)
      assert {:error, :invalid_notification_setting_id} = NotificationSettings.get(client, "")
      assert {:error, :invalid_notification_setting_id} = NotificationSettings.get(client, "   ")
    end

    test "url-encodes notification setting ids before building the request path" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/notification-settings/ntfset%2Fwith%3Freserved"

          {request, Req.Response.new(status: 200, body: %{"data" => setting_payload()})}
        end)

      assert {:ok, %NotificationSetting{}} =
               NotificationSettings.get(client, "ntfset/with?reserved")
    end
  end

  describe "list/2" do
    test "requests the notification settings collection and returns a typed page" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/notification-settings"
          assert request_context(request) == list_request_context()
          assert URI.decode_query(request.url.query) == %{"per_page" => "10"}

          body = %{
            "data" => [setting_payload()],
            "meta" => %{
              "pagination" => %{
                "has_more" => false,
                "estimated_total" => 1,
                "next" => "/notification-settings?after=ntfset_01",
                "per_page" => 10
              },
              "request_id" => "req_123"
            }
          }

          {request, Req.Response.new(status: 200, body: body)}
        end)

      assert {:ok, %Paddle.Page{data: [%NotificationSetting{}]}} =
               NotificationSettings.list(client, per_page: 10)
    end
  end

  describe "stream/2" do
    test "yields items and automatically paginates" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/notification-settings"
          assert request_context(request) == list_request_context()

          query = request.url.query || ""

          if not String.contains?(query, "after=") do
            body = %{
              "data" => [setting_payload()],
              "meta" => %{
                "pagination" => %{
                  "has_more" => true,
                  "estimated_total" => 2,
                  "next" => "/notification-settings?after=ntfset_01",
                  "per_page" => 1
                },
                "request_id" => "req_123"
              }
            }

            {request, Req.Response.new(status: 200, body: body)}
          else
            assert String.contains?(query, "after=ntfset_01")

            body = %{
              "data" => [%{setting_payload() | "id" => "ntfset_02"}],
              "meta" => %{
                "pagination" => %{
                  "has_more" => false,
                  "estimated_total" => 2,
                  "next" => "/notification-settings?after=ntfset_02",
                  "per_page" => 1
                },
                "request_id" => "req_456"
              }
            }

            {request, Req.Response.new(status: 200, body: body)}
          end
        end)

      items = NotificationSettings.stream(client, per_page: 1) |> Enum.to_list()

      assert length(items) == 2

      assert [%NotificationSetting{id: "ntfset_01"}, %NotificationSetting{id: "ntfset_02"}] =
               items
    end
  end

  describe "all/2" do
    test "accumulates items and automatically paginates" do
      client =
        client_with_adapter(fn request ->
          assert request.method == :get
          assert request.url.path == "/notification-settings"
          assert request_context(request) == list_request_context()

          query = request.url.query || ""

          if not String.contains?(query, "after=") do
            body = %{
              "data" => [setting_payload()],
              "meta" => %{
                "pagination" => %{
                  "has_more" => true,
                  "estimated_total" => 2,
                  "next" => "/notification-settings?after=ntfset_01",
                  "per_page" => 1
                },
                "request_id" => "req_123"
              }
            }

            {request, Req.Response.new(status: 200, body: body)}
          else
            assert String.contains?(query, "after=ntfset_01")

            body = %{
              "data" => [%{setting_payload() | "id" => "ntfset_02"}],
              "meta" => %{
                "pagination" => %{
                  "has_more" => false,
                  "estimated_total" => 2,
                  "next" => "/notification-settings?after=ntfset_02",
                  "per_page" => 1
                },
                "request_id" => "req_456"
              }
            }

            {request, Req.Response.new(status: 200, body: body)}
          end
        end)

      assert {:ok, items} = NotificationSettings.all(client)

      assert length(items) == 2

      assert [%NotificationSetting{id: "ntfset_01"}, %NotificationSetting{id: "ntfset_02"}] =
               items
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

  defp assert_public_mutation_option_contract(call, payload) do
    invalid_options = [
      "not-a-keyword",
      [retry: false, retry: true],
      [retry: :secret_retry_value],
      [base_url: "https://credential-canary.example"],
      [auth: {:bearer, "secret-auth-canary"}],
      [headers: [{"authorization", "secret-header-canary"}]],
      [adapter: {:secret_adapter_canary, []}]
    ]

    for opts <- invalid_options do
      {:ok, attempts} = Agent.start_link(fn -> 0 end)

      client =
        client_with_adapter(fn request ->
          Agent.update(attempts, &(&1 + 1))
          flunk("adapter received forbidden notification-setting options")
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

    {:ok, attempts} = Agent.start_link(fn -> 0 end)

    client =
      client_with_adapter(fn request ->
        Agent.update(attempts, &(&1 + 1))
        {request, Req.Response.new(status: 201, body: %{"data" => payload})}
      end)

    assert {:ok, _setting} = call.(client, retry: false)
    assert Agent.get(attempts, & &1) == 1
  end

  defp request_context(request),
    do: Req.Request.get_private(request, :paddle_request_context)

  defp create_request_context,
    do: %{
      method: :post,
      operation: :create_notification_setting,
      route: "/notification-settings"
    }

  defp get_request_context,
    do: %{
      method: :get,
      operation: :get_notification_setting,
      route: "/notification-settings/:notification_setting_id"
    }

  defp list_request_context,
    do: %{
      method: :get,
      operation: :list_notification_settings,
      route: "/notification-settings"
    }

  defp update_request_context(id),
    do: %{
      method: :patch,
      operation: :update_notification_setting,
      resource_id: id,
      route: "/notification-settings/:notification_setting_id"
    }

  defp delete_request_context(id),
    do: %{
      method: :delete,
      operation: :delete_notification_setting,
      resource_id: id,
      route: "/notification-settings/:notification_setting_id"
    }

  defp setting_payload do
    %{
      "id" => "ntfset_01",
      "description" => "Main App Webhook",
      "type" => "url",
      "destination" => "https://example.com/webhooks",
      "active" => true,
      "api_version" => 1,
      "include_sensitive_fields" => true,
      "subscribed_events" => [
        %{"name" => "transaction.completed", "description" => "When a transaction is completed."}
      ]
    }
  end
end
