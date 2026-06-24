defmodule DemoWeb.LoginLive do
  use DemoWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
      <.card class="w-full max-w-md mx-auto p-8 shadow-xl">
        <div class="text-center mb-8">
          <h1 class="text-2xl font-bold text-gray-900 dark:text-white">oarlock Demo App</h1>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-2">
            This is a mock login. No password required.
          </p>
        </div>

        <.form for={%{}} action={~p"/auth/login"} method="post">
          <div class="flex flex-col gap-4">
            <.button type="submit" color="primary" class="w-full justify-center">
              Login as Demo Merchant
            </.button>
          </div>
        </.form>
      </.card>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket, layout: false}
  end
end
