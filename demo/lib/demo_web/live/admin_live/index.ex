defmodule DemoWeb.AdminLive.Index do
  use DemoWeb, :live_view
  alias Demo.Billing
  require Logger

  def render(assigns) do
    ~H"""
    <div id="admin-shell" phx-hook="PaddleCheckout" class="min-h-screen bg-gray-100 dark:bg-gray-900 flex">
      <!-- Sidebar -->
      <aside class="w-64 bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700 flex-shrink-0 hidden md:flex flex-col">
        <div class="h-16 flex items-center px-6 border-b border-gray-200 dark:border-gray-700">
          <span class="text-xl font-bold text-gray-900 dark:text-white">oarlock Demo</span>
        </div>
        <nav class="flex-1 px-4 py-6 space-y-2 overflow-y-auto">
          <a href={~p"/admin"} class="flex items-center gap-3 px-3 py-2 text-sm font-medium rounded-md bg-gray-100 text-gray-900 dark:bg-gray-700 dark:text-white">
            <.icon name="hero-home" class="w-5 h-5 text-gray-500 dark:text-gray-300" />
            Dashboard
          </a>
          <div class="px-3 py-2 text-sm font-medium text-gray-500 flex items-center gap-3">
            <.icon name="hero-shopping-cart" class="w-5 h-5 text-gray-400" />
            Checkout Active
          </div>
          <div class="px-3 py-2 text-sm font-medium text-gray-500 opacity-50 flex items-center gap-3 cursor-not-allowed">
            <.icon name="hero-user" class="w-5 h-5 text-gray-400" />
            Portal (Soon)
          </div>
        </nav>
      </aside>

      <!-- Main Content -->
      <main class="flex-1 flex flex-col min-w-0 overflow-hidden">
        <header class="h-16 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between px-6">
          <h1 class="text-xl font-semibold text-gray-800 dark:text-white">Dashboard</h1>
          <.form for={%{}} action={~p"/auth/logout"} method="post" class="m-0">
            <.button type="submit" variant="outline" size="sm">Logout</.button>
          </.form>
        </header>

        <div class="flex-1 overflow-y-auto p-6 md:p-8">
          <div class="max-w-5xl mx-auto">
            <div class="mb-8">
              <h2 class="text-2xl font-bold text-gray-900 dark:text-white">
                Welcome, <%= @current_user.name %>
              </h2>
              <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
                You are logged in as a mock merchant. The environment is safe for testing.
              </p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <.card>
                <div class="flex flex-col items-center justify-center py-8 text-center px-4">
                  <.icon name="hero-check-circle-solid" class="w-16 h-16 text-green-500 mb-4" />
                  <h3 class="text-xl font-semibold text-gray-900 dark:text-white">System Status</h3>
                  <p class="text-sm text-gray-500 dark:text-gray-400 mt-2">oarlock SDK connected successfully.</p>
                </div>
              </.card>

              <.card>
                <div class="flex flex-col items-center justify-center py-8 text-center px-4">
                  <%= if @subscription do %>
                    <.icon name="hero-star-solid" class="w-16 h-16 text-yellow-500 mb-4" />
                    <h3 class="text-xl font-semibold text-gray-900 dark:text-white">Subscription Active</h3>
                    <p class="text-sm text-gray-500 dark:text-gray-400 mt-2">
                      Status: <span class="capitalize font-semibold text-primary-500"><%= @subscription.status %></span><br/>
                      Renews: <%= Calendar.strftime(@subscription.current_period_end, "%B %d, %Y") %>
                    </p>
                  <% else %>
                    <.icon name="hero-shopping-bag-solid" class="w-16 h-16 text-blue-500 mb-4" />
                    <h3 class="text-xl font-semibold text-gray-900 dark:text-white">No Active Subscription</h3>
                    <p class="text-sm text-gray-500 dark:text-gray-400 mt-2 mb-4">
                      Purchase a plan to unlock premium features.
                    </p>
                    <.button phx-click="subscribe_now" color="primary" disabled={@checkout_loading}>
                      <%= if @checkout_loading, do: "Loading...", else: "Subscribe Now" %>
                    </.button>
                  <% end %>
                </div>
              </.card>
            </div>
          </div>
        </div>
      </main>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Demo.PubSub, "subscriptions:#{socket.assigns.current_user.id}")
    end

    socket =
      socket
      |> assign(:layout, false)
      |> assign(:checkout_loading, false)
      |> load_subscription()

    {:ok, socket, layout: false}
  end

  def handle_info(:subscription_updated, socket) do
    {:noreply, load_subscription(socket)}
  end

  def handle_event("subscribe_now", _, socket) do
    socket = assign(socket, :checkout_loading, true)
    
    # We must instantiate a client context
    client = Paddle.Client.new!(bearer_token: System.get_env("PADDLE_API_KEY") || "pdl_sandbox_test_token")

    # The seeded mock price ID (ensure this exists in sandbox or mock)
    # Using a generic sandbox price format for now
    price_id = System.get_env("PADDLE_TEST_PRICE_ID") || "pri_01j00000000000000000000000"

    # Backend-driven transaction creation
    case Paddle.Transactions.create(client, %{
           items: [%{price_id: price_id, quantity: 1}],
           # Important: inject our mock user id so the webhook knows who owns the resulting subscription
           custom_data: %{"mock_user_id" => socket.assigns.current_user.id}
         }) do
      {:ok, %Paddle.Transaction{} = txn} ->
        # Push event to JS client to open overlay
        socket = 
          socket
          |> assign(:checkout_loading, false)
          |> push_event("open_checkout", %{url: txn.checkout.url})

        {:noreply, socket}

      {:error, error} ->
        Logger.error("Checkout creation failed: #{inspect(error)}")
        socket = 
          socket
          |> assign(:checkout_loading, false)
          |> put_flash(:error, "Failed to initialize checkout.")
        
        {:noreply, socket}
    end
  end

  defp load_subscription(socket) do
    sub = Demo.Repo.get_by(Demo.Billing.Subscription, mock_user_id: socket.assigns.current_user.id)
    assign(socket, :subscription, sub)
  end
end
