defmodule DemoWeb.Router do
  use DemoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :require_auth do
    plug :require_authenticated_user
  end

  pipeline :redirect_if_auth do
    plug :redirect_if_user_is_authenticated
  end

  def require_authenticated_user(conn, opts), do: DemoWeb.MockAuth.require_authenticated_user(conn, opts)
  def redirect_if_user_is_authenticated(conn, opts), do: DemoWeb.MockAuth.redirect_if_user_is_authenticated(conn, opts)

  # Auth endpoints
  scope "/auth", DemoWeb do
    pipe_through :browser
    post "/login", AuthController, :login
    post "/logout", AuthController, :logout
  end

  # Public routes
  scope "/", DemoWeb do
    pipe_through [:browser, :redirect_if_auth]

    live_session :public, on_mount: [{DemoWeb.MockAuth, :redirect_if_user_is_authenticated}] do
      live "/login", LoginLive, :new
      get "/", PageController, :home
    end
  end

  # Admin routes
  scope "/admin", DemoWeb do
    pipe_through [:browser, :require_auth]

    live_session :admin, on_mount: [{DemoWeb.MockAuth, :ensure_authenticated}] do
      live "/", AdminLive.Index, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", DemoWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:demo, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DemoWeb.Telemetry
    end
  end
end
