defmodule DemoWeb.AdminLiveTest do
  use DemoWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  import Demo.BillingFixtures

  @checkout_url "https://sandbox-checkout.paddle.com/mock-checkout-url"
  @portal_url "https://sandbox-my.paddle.com/mock-portal-session"
  @mock_user_id "mock-merchant-123"

  test "start checkout pushes MockServer checkout URL", %{conn: conn} do
    {:ok, view, _html} = conn |> log_in() |> live(~p"/admin")

    view
    |> element("#start-checkout-button", "Start checkout")
    |> render_click()

    assert_push_event(view, "open_checkout", %{url: @checkout_url})
  end

  test "active subscription exposes portal handoff and redirects externally", %{conn: conn} do
    subscription_fixture(%{
      mock_user_id: @mock_user_id,
      paddle_customer_id: "ctm_mock123",
      paddle_subscription_id: "sub_mock123",
      status: "active",
      current_period_end: ~U[2026-07-11 12:00:00Z]
    })

    {:ok, view, html} = conn |> log_in() |> live(~p"/admin")

    assert html =~ "Subscription Active"
    assert has_element?(view, "#manage-billing-button", "Manage billing")

    view
    |> element("#manage-billing-button", "Manage billing")
    |> render_click()

    assert_redirect(view, @portal_url)
  end

  defp log_in(conn) do
    conn = post(conn, ~p"/auth/login", %{})
    assert redirected_to(conn) == ~p"/admin"
    conn
  end
end
