ExUnit.start()

defmodule Paddle.MockServerTest2 do
  use ExUnit.Case, async: false

  setup_all do
    port = 4450
    {:ok, _pid} = Paddle.MockServer.start_link(port: port)
    
    client = Paddle.Client.new!(
      api_key: "sk_test_mock",
      base_url: "http://localhost:#{port}"
    )

    {:ok, client: client}
  end

  test "GET /customers/:id dynamically injects the requested ID", %{client: client} do
    response = Req.get!("#{client.base_url}/customers/ctm_dynamic_789")
    IO.inspect(response.status, label: "Req raw status")

    assert {:ok, %Paddle.Customer{} = customer} = Paddle.Customers.get(client, "ctm_dynamic_789")
    assert customer.id == "ctm_dynamic_789"
  end
end
