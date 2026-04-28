defmodule Paddle.ClientTest do
  use ExUnit.Case, async: true

  test "new!/1 raises when :api_key is missing" do
    assert_raise KeyError, fn ->
      Paddle.Client.new!()
    end
  end

  test "new!/1 returns a configured client with telemetry-enabled req state" do
    client = Paddle.Client.new!(api_key: "sk_test_123", environment: :live)

    assert %Paddle.Client{
             api_key: "sk_test_123",
             environment: :live,
             req: %Req.Request{} = req
           } = client

    assert req.options.auth == {:bearer, "sk_test_123"}
    assert req.options.base_url == "https://api.paddle.com"
    assert req.headers["paddle-version"] == ["1"]
    assert Keyword.has_key?(req.request_steps, :paddle_telemetry_start)
    assert Keyword.has_key?(req.response_steps, :paddle_telemetry_stop)
    assert Keyword.has_key?(req.error_steps, :paddle_telemetry_error)
  end
end
