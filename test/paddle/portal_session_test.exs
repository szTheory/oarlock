defmodule Paddle.PortalSessionTest do
  use ExUnit.Case, async: true
  alias Paddle.PortalSession

  describe "struct" do
    test "has expected fields" do
      session = %PortalSession{
        id: "cptrsess_01hv8...",
        customer_id: "ctm_01hv8...",
        urls: %{
          "general" => %{
            "overview" => "https://buy.paddle.com/portal/session/overview?...",
            "payment_methods" => "https://buy.paddle.com/portal/session/payment-methods?...",
            "subscriptions" => "https://buy.paddle.com/portal/session/subscriptions?..."
          },
          "subscriptions" => [
            %{
              "id" => "sub_01hvg...",
              "cancel_subscription" =>
                "https://buy.paddle.com/portal/session/cancel-subscription?...",
              "update_subscription_payment_method" =>
                "https://buy.paddle.com/portal/session/update-subscription-payment-method?..."
            }
          ]
        },
        created_at: "2024-04-12T10:49:57.652758Z",
        custom_data: %{"foo" => "bar"}
      }

      assert session.id == "cptrsess_01hv8..."
      assert session.customer_id == "ctm_01hv8..."
      assert session.urls["general"]["overview"] =~ "overview"
    end

    test "excludes urls from Inspect" do
      session = %PortalSession{
        id: "cptrsess_01hv8...",
        customer_id: "ctm_01hv8...",
        urls: %{
          "general" => %{
            "overview" => "https://buy.paddle.com/portal/session/overview?secret=true"
          }
        },
        created_at: "2024-04-12T10:49:57.652758Z",
        custom_data: nil
      }

      inspected = inspect(session)

      assert inspected =~ "cptrsess_01hv8"
      assert inspected =~ "ctm_01hv8"
      refute inspected =~ "secret=true"
      assert inspected =~ "urls: \"[REDACTED]\""
    end
  end
end
