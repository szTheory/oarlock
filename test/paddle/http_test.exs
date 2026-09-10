defmodule Paddle.HttpTest do
  use ExUnit.Case, async: true

  defmodule SampleStruct do
    defstruct [:id, :name, :raw_data]
  end

  defmodule Adapter do
    def run(request) do
      request
      |> Req.Request.get_private(:paddle_test_adapter)
      |> then(& &1.(request))
    end
  end

  alias Paddle.Client
  alias Paddle.Error
  alias Paddle.Http

  test "request/4 returns ok tuples for 2xx responses" do
    client =
      client_with_adapter(fn request ->
        {request, Req.Response.new(status: 200, body: %{"data" => %{"id" => "cus_123"}})}
      end)

    assert {:ok, %{"data" => %{"id" => "cus_123"}}} = Http.request(client, :get, "/customers")
  end

  test "request/4 maps non-2xx responses to Paddle.Error" do
    client =
      client_with_adapter(fn request ->
        response =
          Req.Response.new(
            status: 422,
            body: %{
              "error" => %{
                "type" => "validation_error",
                "code" => "invalid_field",
                "detail" => "Email is invalid",
                "errors" => []
              }
            }
          )
          |> Req.Response.put_header("x-request-id", "req_422")

        {request, response}
      end)

    assert {:error,
            %Error{
              status_code: 422,
              request_id: "req_422",
              type: "validation_error",
              code: "invalid_field",
              message: "Email is invalid"
            }} = Http.request(client, :post, "/customers", body: %{})
  end

  test "request/4 normalizes transport exceptions into Paddle.Error" do
    client =
      client_with_adapter(fn request ->
        {request, %Req.TransportError{reason: :timeout}}
      end)

    assert {:error,
            %Paddle.Error{
              network_error?: true,
              retryable?: true,
              type: "network_timeout",
              raw_data: %Req.TransportError{reason: :timeout}
            }} = Http.request(client, :get, "/customers", retry: false)
  end

  test "request/4 maps nxdomain to network_nxdomain type" do
    client =
      client_with_adapter(fn request ->
        {request, %Req.TransportError{reason: :nxdomain}}
      end)

    assert {:error,
            %Paddle.Error{type: "network_nxdomain", network_error?: true, retryable?: true}} =
             Http.request(client, :get, "/customers", retry: false)
  end

  test "request/4 maps closed to network_closed type" do
    client =
      client_with_adapter(fn request ->
        {request, %Req.TransportError{reason: :closed}}
      end)

    assert {:error, %Paddle.Error{type: "network_closed", network_error?: true, retryable?: true}} =
             Http.request(client, :get, "/customers", retry: false)
  end

  test "request/4 maps unknown transport reason to network_unknown type" do
    client =
      client_with_adapter(fn request ->
        {request, %Req.TransportError{reason: :econnrefused}}
      end)

    assert {:error,
            %Paddle.Error{type: "network_unknown", network_error?: true, retryable?: true}} =
             Http.request(client, :get, "/customers", retry: false)
  end

  test "build_struct/2 maps known string keys into the target struct" do
    data = %{"id" => "txn_123", "name" => "Starter", "ignored" => "value"}

    assert %SampleStruct{id: "txn_123", name: "Starter"} = Http.build_struct(SampleStruct, data)
  end

  test "build_struct/2 preserves the raw payload in raw_data" do
    data = %{"id" => "txn_123", "name" => "Starter", "ignored" => "value"}

    assert %SampleStruct{raw_data: ^data} = Http.build_struct(SampleStruct, data)
  end

  test "request/4 rejects unsupported idempotency_key before dispatch" do
    {:ok, attempts} = Agent.start_link(fn -> 0 end)

    client =
      client_with_adapter(fn request ->
        Agent.update(attempts, &(&1 + 1))
        {request, Req.Response.new(status: 201, body: %{})}
      end)

    assert_raise ArgumentError, ~r/idempotency_key is not supported/, fn ->
      Http.request(client, :post, "/customers", idempotency_key: "unsupported-canary")
    end

    assert Agent.get(attempts, & &1) == 0
  end

  describe "request/4 retry policy" do
    test "eligible GET and HEAD status failures stop after four attempts" do
      for method <- [:get, :head], status <- [408, 429, 500, 502, 503, 504] do
        {result, attempts} = persistent_response(method, status)
        assert {:error, %Error{status_code: ^status}} = result
        assert attempts == 4
      end
    end

    test "eligible GET and HEAD transport failures stop after four attempts" do
      for method <- [:get, :head], reason <- [:timeout, :econnrefused, :closed] do
        {result, attempts} = persistent_transport(method, reason)
        assert {:error, %Error{network_error?: true}} = result
        assert attempts == 4
      end
    end

    test "ineligible status and transport failures execute once" do
      for status <- [400, 401, 404, 409, 422, 501] do
        {result, attempts} = persistent_response(:get, status)
        assert {:error, %Error{status_code: ^status}} = result
        assert attempts == 1
      end

      for reason <- [:nxdomain, :enetunreach, :unknown] do
        {result, attempts} = persistent_transport(:get, reason)
        assert {:error, %Error{network_error?: true}} = result
        assert attempts == 1
      end
    end

    test "mutations and retry: false reads execute exactly once" do
      for method <- [:post, :patch, :put, :delete] do
        {result, attempts} = persistent_response(method, 503)
        assert {:error, %Error{status_code: 503}} = result
        assert attempts == 1
      end

      {result, attempts} = persistent_response(:get, 503, retry: false)
      assert {:error, %Error{status_code: 503}} = result
      assert attempts == 1
    end

    test "retry: true cannot enable mutation replay and invalid values fail before dispatch" do
      for {method, retry} <- [
            {:post, true},
            {:patch, true},
            {:put, true},
            {:delete, true},
            {:get, :always}
          ] do
        {:ok, attempts} = Agent.start_link(fn -> 0 end)

        client =
          client_with_retry_adapter(fn request ->
            Agent.update(attempts, &(&1 + 1))
            {request, Req.Response.new(status: 503, body: %{})}
          end)

        assert_raise ArgumentError, ~r/retry/, fn ->
          Http.request(client, method, "/resource", retry: retry)
        end

        assert Agent.get(attempts, & &1) == 0
      end
    end

    test "only 429 Retry-After is honored and capped at 60000 ms" do
      parent = self()

      client =
        client_with_adapter(fn request ->
          retry = Req.Request.get_option(request, :retry)

          retry_after =
            Req.Response.new(status: 429)
            |> Req.Response.put_header("retry-after", "120")

          service_unavailable =
            Req.Response.new(status: 503)
            |> Req.Response.put_header("retry-after", "120")

          send(
            parent,
            {:decisions, retry.(request, retry_after), retry.(request, service_unavailable)}
          )

          {request, Req.Response.new(status: 200, body: %{})}
        end)

      assert {:ok, %{}} = Http.request(client, :get, "/customers")
      assert_receive {:decisions, {:delay, 60_000}, true}
    end

    test "parallel callers keep independent attempt counters and terminal outcomes" do
      requests = [
        {:get, 503, 4},
        {:head, 408, 4},
        {:post, 503, 1},
        {:delete, 429, 1},
        {:get, 422, 1}
      ]

      results =
        requests
        |> Task.async_stream(
          fn {method, status, expected_attempts} ->
            {result, attempts} = persistent_response(method, status)
            {status, expected_attempts, attempts, result}
          end,
          ordered: false
        )
        |> Enum.map(fn {:ok, result} -> result end)

      for {status, expected_attempts, attempts, result} <- results do
        assert attempts == expected_attempts
        assert {:error, %Error{status_code: ^status}} = result
      end
    end
  end

  describe "request/4 ambiguous mutation outcomes" do
    test "transport failures are non-retryable ambiguity with safe reconciliation context" do
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
                operation: :create_customer,
                resource_id: "ctm_safe_01",
                reconciliation: [:lookup, :webhook, :provider_dashboard]
              }} =
               Http.request(client, :post, "/customers",
                 operation: :create_customer,
                 route: "/customers",
                 resource_id: "ctm_safe_01"
               )

      assert Agent.get(attempts, & &1) == 1
    end

    test "408 and 5xx mutation responses are ambiguous without replay" do
      for status <- [408, 500, 501, 502, 503, 504] do
        {:ok, attempts} = Agent.start_link(fn -> 0 end)

        client =
          client_with_adapter(fn request ->
            Agent.update(attempts, &(&1 + 1))
            {request, Req.Response.new(status: status, body: %{})}
          end)

        assert {:error, %Error{status_code: ^status, ambiguous?: true, retryable?: false}} =
                 Http.request(client, :patch, "/subscriptions/sub_01",
                   operation: :update_subscription,
                   route: "/subscriptions/:subscription_id",
                   resource_id: "sub_01"
                 )

        assert Agent.get(attempts, & &1) == 1
      end
    end

    test "repeated dispatch of one mutation input never replays and returns the same contract" do
      {:ok, attempts} = Agent.start_link(fn -> 0 end)

      client =
        client_with_adapter(fn request ->
          Agent.update(attempts, &(&1 + 1))
          {request, %Req.TransportError{reason: :closed}}
        end)

      request = fn ->
        Http.request(client, :post, "/transactions",
          json: %{items: []},
          operation: :create_transaction,
          route: "/transactions"
        )
      end

      assert {:error, %Error{} = first} = request.()
      assert {:error, %Error{} = second} = request.()
      assert first == second
      assert first.ambiguous?
      refute first.retryable?
      assert Agent.get(attempts, & &1) == 2
    end

    test "parallel mutations retain independent context and terminal results" do
      operations = [
        {:create_customer, "ctm_01", :timeout},
        {:update_subscription, "sub_02", :closed},
        {:cancel_subscription, "sub_03", :econnrefused}
      ]

      results =
        operations
        |> Task.async_stream(fn {operation, resource_id, reason} ->
          client =
            client_with_adapter(fn request ->
              {request, %Req.TransportError{reason: reason}}
            end)

          Http.request(client, :post, "/mutation",
            operation: operation,
            route: "/mutation",
            resource_id: resource_id
          )
        end)
        |> Enum.map(fn {:ok, result} -> result end)

      assert Enum.sort(
               Enum.map(results, fn
                 {:error, %Error{} = error} ->
                   {error.operation, error.resource_id, error.ambiguous?, error.retryable?}
               end)
             ) ==
               Enum.sort([
                 {:create_customer, "ctm_01", true, false},
                 {:update_subscription, "sub_02", true, false},
                 {:cancel_subscription, "sub_03", true, false}
               ])
    end
  end

  defp client_with_adapter(adapter) do
    %Client{
      api_key: "sk_test_123",
      environment: :sandbox,
      base_url: "https://sandbox-api.paddle.com",
      req:
        Req.new(
          base_url: "https://sandbox-api.paddle.com",
          retry: false,
          adapter: Adapter
        )
        |> Req.Request.put_private(:paddle_test_adapter, adapter)
    }
  end

  defp client_with_retry_adapter(adapter) do
    %Client{
      api_key: "sk_test_123",
      environment: :sandbox,
      base_url: "https://sandbox-api.paddle.com",
      req:
        Req.new(
          base_url: "https://sandbox-api.paddle.com",
          retry: :transient,
          max_retries: 3,
          retry_delay: 0,
          retry_log_level: false,
          adapter: Adapter
        )
        |> Req.Request.put_private(:paddle_test_adapter, adapter)
    }
  end

  defp persistent_response(method, status, opts \\ []) do
    {:ok, attempts} = Agent.start_link(fn -> 0 end)

    client =
      client_with_retry_adapter(fn request ->
        Agent.update(attempts, &(&1 + 1))
        {request, Req.Response.new(status: status, body: %{})}
      end)

    result = Http.request(client, method, "/resource", opts)
    {result, Agent.get(attempts, & &1)}
  end

  defp persistent_transport(method, reason) do
    {:ok, attempts} = Agent.start_link(fn -> 0 end)

    client =
      client_with_retry_adapter(fn request ->
        Agent.update(attempts, &(&1 + 1))
        {request, %Req.TransportError{reason: reason}}
      end)

    result = Http.request(client, method, "/resource")
    {result, Agent.get(attempts, & &1)}
  end
end
