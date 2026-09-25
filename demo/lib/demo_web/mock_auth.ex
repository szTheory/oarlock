defmodule DemoWeb.MockAuth do
  import Plug.Conn
  import Phoenix.Controller
  alias Phoenix.LiveView

  @mock_user %Demo.Accounts.User{
    id: "mock-merchant-123",
    name: "Demo Merchant",
    email: "demo@merchant.local"
  }

  # --- Plug for standard Controllers ---

  def require_authenticated_user(conn, _opts) do
    if get_session(conn, :mock_user_id) do
      assign(conn, :current_user, @mock_user)
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> redirect(to: "/login")
      |> halt()
    end
  end

  def redirect_if_user_is_authenticated(conn, _opts) do
    if get_session(conn, :mock_user_id) do
      conn
      |> redirect(to: "/admin")
      |> halt()
    else
      conn
    end
  end

  def log_in_user(conn, user_id) do
    conn
    |> put_session(:mock_user_id, user_id)
    |> configure_session(renew: true)
    |> redirect(to: "/admin")
  end

  def log_out_user(conn) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end

  # --- LiveView on_mount Hook ---

  def on_mount(:ensure_authenticated, _params, session, socket) do
    if session["mock_user_id"] do
      {:cont, Phoenix.Component.assign(socket, :current_user, @mock_user)}
    else
      {:halt, LiveView.redirect(socket, to: "/login")}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    if session["mock_user_id"] do
      {:halt, LiveView.redirect(socket, to: "/admin")}
    else
      {:cont, Phoenix.Component.assign(socket, :current_user, nil)}
    end
  end
end
