defmodule DemoWeb.AuthController do
  use DemoWeb, :controller

  alias DemoWeb.MockAuth

  def login(conn, _params) do
    # In a real app we'd verify credentials. Here we just set a static mock user.
    MockAuth.log_in_user(conn, "mock-merchant-123")
  end

  def logout(conn, _params) do
    MockAuth.log_out_user(conn)
  end
end
