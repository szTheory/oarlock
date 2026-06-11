defmodule Paddle.MockServer do
  @moduledoc """
  A standalone Plug Router that simulates the Paddle Billing API.

  This server can be started in your application's supervision tree during
  development or testing to allow fully offline development without hitting
  the real Paddle sandbox.

  ## Example Usage

  In your `test_helper.exs` or `application.ex`:

  ```elixir
  # Start the server on port 4001
  {:ok, _pid} = Paddle.MockServer.start_link(port: 4001)

  # Configure the SDK client
  client = Paddle.Client.new!(
    api_key: "sk_test_mock",
    base_url: "http://localhost:4001"
  )
  ```
  """

  use Plug.Router
  alias Paddle.MockServer.Fixtures

  plug :match
  plug Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Jason
  plug :dispatch

  @doc """
  Starts the Bandit server wrapping this Plug router.
  Accepts a `:port` option (defaults to 4001).
  """
  def start_link(opts \\ []) do
    port = Keyword.get(opts, :port, 4001)
    Bandit.start_link(plug: __MODULE__, port: port)
  end

  # --- Customers ---

  post "/customers" do
    send_json(conn, 201, Fixtures.customer())
  end

  get "/customers/:id" do
    send_json(conn, 200, Fixtures.customer(id))
  end

  patch "/customers/:id" do
    send_json(conn, 200, Fixtures.customer(id))
  end

  # --- Portal Sessions ---

  post "/customers/:id/portal-sessions" do
    send_json(conn, 201, Fixtures.portal_session(id))
  end

  # --- Transactions ---

  post "/transactions" do
    send_json(conn, 201, Fixtures.transaction())
  end

  get "/transactions/:id" do
    send_json(conn, 200, Fixtures.transaction(id))
  end

  # --- Fallback ---

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{error: %{message: "Mock route not found"}}))
  end

  defp send_json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(%{data: data}))
  end
end
