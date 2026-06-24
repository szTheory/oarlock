defmodule Paddle.MockServer do
  @moduledoc """
  An optional local HTTP fixture that simulates the Paddle Billing API.

  This server can be started in your application's supervision tree during
  development or testing to allow fully offline development without hitting
  the real Paddle sandbox.

  `Paddle.MockServer` requires the optional `:plug` and `:bandit` dependencies.
  The core SDK compiles without them; calling `start_link/1` without those
  dependencies returns a clear error.

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

  @doc """
  Starts the Bandit server wrapping this Plug router.
  Accepts a `:port` option (defaults to 4001).
  """
  @spec start_link(keyword()) :: {:ok, pid()} | {:error, term()}
  def start_link(opts \\ []) do
    with :ok <- ensure_optional_deps() do
      port = Keyword.get(opts, :port, 4001)
      bandit = Module.concat([Bandit])

      apply(bandit, :start_link, [[plug: __MODULE__.Router, port: port]])
    end
  end

  defp ensure_optional_deps do
    missing =
      [
        {:plug, Plug.Router},
        {:plug, Plug.Parsers},
        {:bandit, Bandit}
      ]
      |> Enum.reject(fn {_app, module} -> Code.ensure_loaded?(module) end)
      |> Enum.map(&elem(&1, 0))
      |> Enum.uniq()

    case missing do
      [] ->
        :ok

      apps ->
        {:error,
         %RuntimeError{
           message:
             "Paddle.MockServer requires optional dependencies #{format_apps(apps)}. " <>
               "Add them to your Mix dependencies to use the offline development/test fixture."
         }}
    end
  end

  defp format_apps(apps) do
    apps
    |> Enum.map(&inspect/1)
    |> Enum.join(" and ")
  end

  if Code.ensure_loaded?(Plug.Router) and Code.ensure_loaded?(Plug.Parsers) and
       Code.ensure_loaded?(Bandit) do
    defmodule Router do
      @moduledoc false

      use Plug.Router
      alias Paddle.MockServer.Fixtures

      plug(:match)
      plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Jason)
      plug(:dispatch)

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

      # --- Subscriptions ---

      patch "/subscriptions/:id" do
        mode = conn.body_params["proration_billing_mode"]

        fixture =
          if mode == "next_billing_period" do
            Fixtures.subscription_scheduled_change(id)
          else
            Fixtures.subscription_updated(id)
          end

        send_json(conn, 200, fixture)
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
  end
end
