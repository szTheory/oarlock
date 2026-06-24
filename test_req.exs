defmodule Test do
  use ExUnit.Case
  test "what" do
    port = 4448
    {:ok, _pid} = Paddle.MockServer.start_link(port: port)
    client = Paddle.Client.new!(api_key: "sk_test_mock", base_url: "http://localhost:#{port}")
    IO.inspect(client.req.options.base_url)
    res = Paddle.Customers.get(client, "ctm_123")
    IO.inspect(res)
  end
end
ExUnit.start()
