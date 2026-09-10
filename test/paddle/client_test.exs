defmodule Paddle.ClientTest do
  use ExUnit.Case, async: true

  alias Paddle.Client

  defmodule Adapter do
    def run(request) do
      callback = Req.Request.get_private(request, :paddle_test_adapter)
      callback.(request)
    end
  end

  @sandbox_url "https://sandbox-api.paddle.com"
  @live_url "https://api.paddle.com"

  describe "new!/1" do
    test "accepts every coherent environment and base URL combination" do
      cases = [
        {[api_key: "key-default"], :sandbox, @sandbox_url},
        {[api_key: "key-sandbox", environment: :sandbox], :sandbox, @sandbox_url},
        {[api_key: "key-live", environment: :live], :live, @live_url},
        {[api_key: "key-sandbox-url", base_url: @sandbox_url], :sandbox, @sandbox_url},
        {[api_key: "key-live-url", base_url: @live_url], :live, @live_url},
        {[api_key: "key-custom-url", base_url: "http://localhost:4001"], :custom,
         "http://localhost:4001"},
        {[api_key: "key-explicit-sandbox", environment: :sandbox, base_url: @sandbox_url],
         :sandbox, @sandbox_url},
        {[api_key: "key-explicit-live", environment: :live, base_url: @live_url], :live,
         @live_url},
        {[api_key: "key-explicit-custom", environment: :custom, base_url: "https://mock.test"],
         :custom, "https://mock.test"}
      ]

      for {opts, expected_environment, expected_url} <- cases do
        assert %Client{
                 environment: ^expected_environment,
                 base_url: ^expected_url,
                 req: %Req.Request{} = req
               } = Client.new!(opts)

        assert req.options.base_url == expected_url
      end
    end

    test "keeps the API key and telemetry-enabled request state usable" do
      client = Client.new!(api_key: "sk_test_123", environment: :live)

      assert client.api_key == "sk_test_123"
      assert client.req.options.auth == {:bearer, "sk_test_123"}
      assert client.req.headers["paddle-version"] == ["1"]
      assert Keyword.has_key?(client.req.request_steps, :paddle_telemetry_start)
      assert Keyword.has_key?(client.req.response_steps, :paddle_telemetry_stop)
      assert Keyword.has_key?(client.req.error_steps, :paddle_telemetry_error)
    end

    test "rejects missing, blank, whitespace, and nonbinary API keys without disclosure" do
      cases = [
        {[], nil},
        {[api_key: ""], nil},
        {[api_key: "  \t\n"], nil},
        {[api_key: {:secret_key_canary, 41}], "secret_key_canary"}
      ]

      for {opts, canary} <- cases do
        exception = assert_raise ArgumentError, fn -> Client.new!(opts) end

        assert exception.message =~ ":api_key"
        if canary, do: refute(exception.message =~ canary)
      end
    end

    test "rejects unknown and duplicate options without rendering values" do
      cases = [
        {[api_key: "valid", unexpected: "unknown_value_canary"], ":unexpected",
         "unknown_value_canary"},
        {[api_key: "valid", api_key: "duplicate_key_canary"], ":api_key", "duplicate_key_canary"},
        {[api_key: "valid", environment: :sandbox, environment: :live], ":environment", nil},
        {[api_key: "valid", base_url: @sandbox_url, base_url: "duplicate_url_canary"],
         ":base_url", "duplicate_url_canary"}
      ]

      for {opts, option_name, canary} <- cases do
        exception = assert_raise ArgumentError, fn -> Client.new!(opts) end

        assert exception.message =~ option_name
        if canary, do: refute(exception.message =~ canary)
      end
    end

    test "rejects unsupported environments and incoherent explicit URLs without disclosure" do
      cases = [
        {[api_key: "valid", environment: :staging], ":environment", nil},
        {[api_key: "valid", environment: :custom], ":base_url", nil},
        {[api_key: "valid", environment: :sandbox, base_url: @live_url], ":base_url", nil},
        {[api_key: "valid", environment: :live, base_url: @sandbox_url], ":base_url", nil},
        {[
           api_key: "valid",
           environment: :sandbox,
           base_url: "https://url-user:url-pass@example.test?token=url_query_canary"
         ], ":base_url", "url_query_canary"},
        {[
           api_key: "valid",
           environment: :live,
           base_url: "https://url-user:url-pass@example.test?token=url_query_canary"
         ], ":base_url", "url-user"}
      ]

      for {opts, option_name, canary} <- cases do
        exception = assert_raise ArgumentError, fn -> Client.new!(opts) end

        assert exception.message =~ option_name
        if canary, do: refute(exception.message =~ canary)
      end
    end

    test "rejects non-HTTP, relative, hostless, and nonbinary base URLs without disclosure" do
      cases = [
        "relative/url/base_url_canary",
        "ftp://base-url-canary.example",
        "https://?token=base_url_query_canary",
        {:base_url_canary, 42}
      ]

      for invalid_url <- cases do
        exception =
          assert_raise ArgumentError, fn ->
            Client.new!(api_key: "valid", base_url: invalid_url)
          end

        assert exception.message =~ ":base_url"
        refute exception.message =~ "base_url_canary"
      end
    end

    test "fails before transport construction or dispatch for invalid options" do
      {:ok, dispatches} = Agent.start_link(fn -> 0 end)

      exception =
        assert_raise ArgumentError, fn ->
          Client.new!(
            api_key: "valid",
            adapter: fn request ->
              Agent.update(dispatches, &(&1 + 1))
              {request, Req.Response.new(status: 200)}
            end
          )
        end

      assert exception.message =~ ":adapter"
      assert Agent.get(dispatches, & &1) == 0
    end

    test "base-URL-only custom client performs one adapter-backed request" do
      {:ok, dispatches} = Agent.start_link(fn -> 0 end)
      client = Client.new!(api_key: "valid", base_url: "http://mock.example:4447")

      req =
        client.req
        |> Map.replace!(:adapter, Adapter)
        |> Req.Request.put_private(:paddle_test_adapter, fn request ->
          Agent.update(dispatches, &(&1 + 1))

          {request,
           Req.Response.new(
             status: 200,
             body: %{"url" => URI.to_string(request.url)}
           )}
        end)

      client = %{client | req: req}

      assert client.environment == :custom

      assert {:ok, %{"url" => "http://mock.example:4447/probe"}} =
               Paddle.Http.request(client, :get, "/probe")

      assert Agent.get(dispatches, & &1) == 1
    end
  end
end
