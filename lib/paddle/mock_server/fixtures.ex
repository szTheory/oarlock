defmodule Paddle.MockServer.Fixtures do
  @moduledoc """
  Simulated JSON payloads representing Paddle Billing API responses.
  These fixtures are dynamic and can inject specific IDs into the response.
  """

  def customer(id \\ "ctm_mock123") do
    %{
      "id" => id,
      "name" => "Mock Customer",
      "email" => "mock@example.com",
      "status" => "active",
      "locale" => "en",
      "custom_data" => %{},
      "created_at" => "2026-01-01T12:00:00.000000Z",
      "updated_at" => "2026-01-01T12:00:00.000000Z"
    }
  end

  def transaction(id \\ "txn_mock123") do
    %{
      "id" => id,
      "status" => "draft",
      "customer_id" => nil,
      "address_id" => nil,
      "business_id" => nil,
      "custom_data" => %{},
      "currency_code" => "USD",
      "origin" => "api",
      "subscription_id" => nil,
      "invoice_id" => nil,
      "invoice_number" => nil,
      "collection_mode" => "automatic",
      "discount_id" => nil,
      "billing_details" => nil,
      "billing_period" => nil,
      "items" => [],
      "details" => %{
        "tax_rates_used" => [],
        "totals" => %{
          "subtotal" => "0",
          "discount" => "0",
          "tax" => "0",
          "total" => "0",
          "credit" => "0",
          "balance" => "0",
          "grand_total" => "0",
          "fee" => "0",
          "earnings" => "0",
          "currency_code" => "USD"
        },
        "adjusted_totals" => %{
          "subtotal" => "0",
          "discount" => "0",
          "tax" => "0",
          "total" => "0",
          "grand_total" => "0",
          "fee" => "0",
          "earnings" => "0",
          "currency_code" => "USD"
        },
        "payout_totals" => %{
          "subtotal" => "0",
          "discount" => "0",
          "tax" => "0",
          "total" => "0",
          "credit" => "0",
          "balance" => "0",
          "grand_total" => "0",
          "fee" => "0",
          "earnings" => "0",
          "currency_code" => "USD"
        },
        "line_items" => []
      },
      "payments" => [],
      "checkout" => %{
        "url" => "https://sandbox-checkout.paddle.com/mock-checkout-url"
      },
      "created_at" => "2026-01-01T12:00:00.000000Z",
      "updated_at" => "2026-01-01T12:00:00.000000Z"
    }
  end

  def portal_session(customer_id \\ "ctm_mock123") do
    %{
      "id" => "pts_mock123",
      "customer_id" => customer_id,
      "urls" => %{
        "general" => %{
          "url" => "https://sandbox-my.paddle.com/mock-portal-session"
        }
      },
      "created_at" => "2026-01-01T12:00:00.000000Z"
    }
  end

  def subscription_updated(id \\ "sub_mock123") do
    %{
      "id" => id,
      "status" => "active",
      "customer_id" => "ctm_mock123",
      "address_id" => "add_mock123",
      "business_id" => nil,
      "currency_code" => "USD",
      "collection_mode" => "automatic",
      "custom_data" => %{},
      "items" => [],
      "scheduled_change" => nil,
      "management_urls" => %{
        "update_payment_method" => "https://buyer-portal.paddle.com/subscriptions/#{id}/update-payment-method",
        "cancel" => "https://buyer-portal.paddle.com/subscriptions/#{id}/cancel"
      },
      "current_billing_period" => %{
        "starts_at" => "2026-01-01T12:00:00.000000Z",
        "ends_at" => "2026-02-01T12:00:00.000000Z"
      },
      "billing_cycle" => %{"frequency" => 1, "interval" => "month"},
      "billing_details" => nil,
      "discount" => nil,
      "next_billed_at" => "2026-02-01T12:00:00.000000Z",
      "started_at" => "2026-01-01T12:00:00.000000Z",
      "first_billed_at" => "2026-01-01T12:00:00.000000Z",
      "paused_at" => nil,
      "canceled_at" => nil,
      "created_at" => "2026-01-01T12:00:00.000000Z",
      "updated_at" => "2026-01-15T12:00:00.000000Z",
      "import_meta" => nil
    }
  end

  def subscription_scheduled_change(id \\ "sub_mock123") do
    base = subscription_updated(id)
    Map.put(base, "scheduled_change", %{
      "action" => "pause",
      "effective_at" => "2026-12-01T12:00:00Z",
      "resume_at" => nil
    })
  end
end
