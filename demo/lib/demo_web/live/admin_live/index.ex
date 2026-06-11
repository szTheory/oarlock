defmodule DemoWeb.AdminLive.Index do
  use DemoWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-100 dark:bg-gray-900 flex">
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
          <div class="px-3 py-2 text-sm font-medium text-gray-500 opacity-50 flex items-center gap-3 cursor-not-allowed">
            <.icon name="hero-shopping-cart" class="w-5 h-5 text-gray-400" />
            Checkout (Soon)
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
                <div class="flex flex-col items-center justify-center py-8">
                  <.icon name="hero-check-circle-solid" class="w-16 h-16 text-green-500 mb-4" />
                  <h3 class="text-xl font-semibold text-gray-900 dark:text-white">System Status</h3>
                  <p class="text-sm text-gray-500 dark:text-gray-400 mt-2">oarlock SDK connected successfully.</p>
                </div>
              </.card>

              <.card>
                <div class="flex flex-col items-center justify-center py-8">
                  <.icon name="hero-cog-8-tooth-solid" class="w-16 h-16 text-blue-500 mb-4" />
                  <h3 class="text-xl font-semibold text-gray-900 dark:text-white">Next Steps</h3>
                  <p class="text-sm text-gray-500 dark:text-gray-400 mt-2">Phase 22 will introduce Paddle Checkout.</p>
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
    {:ok, socket, layout: false}
  end
end
