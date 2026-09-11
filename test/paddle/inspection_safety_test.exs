defmodule Paddle.InspectionSafetyTest do
  use ExUnit.Case, async: true

  alias Paddle.Client
  alias Paddle.Error
  alias Paddle.Http
  alias Paddle.NotificationSetting
  alias Paddle.PortalSession
  alias Paddle.Subscription.ManagementUrls
  alias Paddle.Transaction.Checkout

  @raw_data_inventory %{
    "Paddle.Address" => [],
    "Paddle.Adjustment" => [],
    "Paddle.Customer" => [],
    "Paddle.Error" => [:raw_data],
    "Paddle.Event" => [],
    "Paddle.NotificationSetting" => [:destination, :endpoint_secret_key, :raw_data],
    "Paddle.PortalSession" => [:urls, :raw_data],
    "Paddle.Price" => [],
    "Paddle.Product" => [],
    "Paddle.Subscription" => [],
    "Paddle.Subscription.ManagementUrls" => [:update_payment_method, :cancel, :raw_data],
    "Paddle.Subscription.ScheduledChange" => [],
    "Paddle.Transaction" => [],
    "Paddle.Transaction.Checkout" => [:url, :raw_data]
  }

  @capability_inventory %{
    Client => %{visible: [:environment], redacted: [:api_key, :base_url, :req]},
    Error => %{
      visible: [
        :type,
        :code,
        :message,
        :errors,
        :request_id,
        :status_code,
        :network_error?,
        :retryable?,
        :ambiguous?,
        :operation,
        :resource_id,
        :reconciliation,
        :__exception__
      ],
      redacted: [:raw_data]
    },
    NotificationSetting => %{
      visible: [
        :id,
        :description,
        :type,
        :active,
        :api_version,
        :include_sensitive_fields,
        :subscribed_events
      ],
      redacted: [:destination, :endpoint_secret_key, :raw_data]
    },
    PortalSession => %{
      visible: [:id, :customer_id, :created_at, :custom_data],
      redacted: [:urls, :raw_data]
    },
    ManagementUrls => %{
      visible: [],
      redacted: [:update_payment_method, :cancel, :raw_data]
    },
    Checkout => %{visible: [], redacted: [:url, :raw_data]}
  }

  test "source inventory explicitly classifies every public raw_data value" do
    discovered =
      "lib/paddle/**/*.ex"
      |> Path.wildcard()
      |> Enum.flat_map(fn path -> path |> File.read!() |> raw_data_modules_from_source!() end)
      |> MapSet.new()

    assert discovered == MapSet.new(Map.keys(@raw_data_inventory))

    assert Enum.all?(@raw_data_inventory, fn {_module, fields} ->
             is_list(fields) and Enum.uniq(fields) == fields
           end)

    assert Enum.all?(
             Enum.filter(@raw_data_inventory, fn {_module, fields} -> fields != [] end),
             fn {_module, fields} -> :raw_data in fields end
           )

    for {module, %{visible: visible, redacted: redacted}} <- @capability_inventory do
      public_fields = module |> struct() |> Map.from_struct() |> Map.keys() |> MapSet.new()
      classified_fields = MapSet.new(visible ++ redacted)

      assert public_fields == classified_fields,
             "#{inspect(module)} has an unclassified or stale public field"

      assert MapSet.disjoint?(MapSet.new(visible), MapSet.new(redacted))
    end
  end

  test "source inventory discovers sibling raw_data modules independently" do
    source = """
    defmodule Paddle.InventoryFixture.StructValue do
      defstruct [:id, :raw_data]
    end

    defmodule Paddle.InventoryFixture.ExceptionValue do
      defexception message: nil, raw_data: nil
    end
    """

    assert source |> raw_data_modules_from_source!() |> MapSet.new() ==
             MapSet.new([
               "Paddle.InventoryFixture.StructValue",
               "Paddle.InventoryFixture.ExceptionValue"
             ])
  end

  test "all six capability-bearing values redact promoted, nested, and transport canaries" do
    for {value, canaries, redacted_fields, visible_fragment} <- inspection_cases() do
      original = value

      assert MapSet.new(canaries_present(value, canaries)) == MapSet.new(canaries)

      rendered = inspect(value)

      assert rendered =~ visible_fragment

      for field <- redacted_fields do
        assert rendered =~ ~s(#{field}: "[REDACTED]")
      end

      assert canaries_present(rendered, canaries) == []
      assert value == original
    end
  end

  test "capability inspection is total for empty protected fields" do
    for module <- Map.keys(@capability_inventory) do
      assert is_binary(module |> struct() |> inspect())
    end
  end

  defp inspection_cases do
    client =
      Client.new!(
        api_key: "promoted_client_key_canary",
        base_url: "https://client.test/path?token=promoted_client_url_canary"
      )

    client = %{
      client
      | req:
          client.req
          |> Req.merge(auth: {:bearer, "nested_client_req_canary"})
          |> Req.Request.put_header("authorization", "Bearer nested_client_header_canary")
    }

    error =
      Error.from_response(
        Req.Response.new(
          status: 500,
          body: %{
            "error" => %{"detail" => "Visible provider failure"},
            "provider_extension" => %{
              "secret" => {"nested_error_tuple_canary", ["nested_error_list_canary"]}
            }
          }
        ),
        %{method: :get, operation: :inspect_safety}
      )

    notification =
      Http.build_struct(NotificationSetting, %{
        "id" => "ntfset_safe_visible",
        "description" => "Visible notification description",
        "destination" => "https://notify.test/promoted_destination_canary",
        "endpoint_secret_key" => "promoted_endpoint_secret_canary",
        "provider_extension" => %{
          "signed_url" => "https://provider.test/nested_notification_url_canary",
          "credentials" =>
            {"nested_notification_tuple_canary", ["nested_notification_list_canary"]}
        }
      })

    portal =
      Http.build_struct(PortalSession, %{
        "id" => "cptrsess_safe_visible",
        "customer_id" => "ctm_safe_visible",
        "urls" => %{
          "general" => %{"overview" => "https://portal.test/promoted_portal_url_canary"}
        },
        "provider_extension" => %{
          "signed_url" => "https://provider.test/nested_portal_url_canary",
          "credentials" => {"nested_portal_tuple_canary", ["nested_portal_list_canary"]}
        }
      })

    management_urls =
      Http.build_struct(ManagementUrls, %{
        "update_payment_method" => "https://manage.test/update/promoted_management_update_canary",
        "cancel" => "https://manage.test/cancel/promoted_management_cancel_canary",
        "provider_extension" => %{
          "signed_url" => "https://provider.test/nested_management_url_canary",
          "credentials" => {"nested_management_tuple_canary", ["nested_management_list_canary"]}
        }
      })

    checkout =
      Http.build_struct(Checkout, %{
        "url" => "https://checkout.test/pay/promoted_checkout_url_canary",
        "provider_extension" => %{
          "signed_url" => "https://provider.test/nested_checkout_url_canary",
          "credentials" => {"nested_checkout_tuple_canary", ["nested_checkout_list_canary"]}
        }
      })

    [
      {client,
       [
         "promoted_client_key_canary",
         "promoted_client_url_canary",
         "nested_client_req_canary",
         "nested_client_header_canary"
       ], [:api_key, :base_url, :req], "environment: :custom"},
      {error, ["nested_error_tuple_canary", "nested_error_list_canary"], [:raw_data],
       "Visible provider failure"},
      {notification,
       [
         "promoted_destination_canary",
         "promoted_endpoint_secret_canary",
         "nested_notification_url_canary",
         "nested_notification_tuple_canary",
         "nested_notification_list_canary"
       ], [:destination, :endpoint_secret_key, :raw_data], "ntfset_safe_visible"},
      {portal,
       [
         "promoted_portal_url_canary",
         "nested_portal_url_canary",
         "nested_portal_tuple_canary",
         "nested_portal_list_canary"
       ], [:urls, :raw_data], "cptrsess_safe_visible"},
      {management_urls,
       [
         "promoted_management_update_canary",
         "promoted_management_cancel_canary",
         "nested_management_url_canary",
         "nested_management_tuple_canary",
         "nested_management_list_canary"
       ], [:update_payment_method, :cancel, :raw_data], "Paddle.Subscription.ManagementUrls"},
      {checkout,
       [
         "promoted_checkout_url_canary",
         "nested_checkout_url_canary",
         "nested_checkout_tuple_canary",
         "nested_checkout_list_canary"
       ], [:url, :raw_data], "Paddle.Transaction.Checkout"}
    ]
  end

  defp canaries_present(term, canaries) when is_struct(term) do
    term |> Map.from_struct() |> canaries_present(canaries)
  end

  defp canaries_present(term, canaries) when is_map(term) do
    Enum.flat_map(term, fn {key, value} ->
      canaries_present(key, canaries) ++ canaries_present(value, canaries)
    end)
  end

  defp canaries_present(term, canaries) when is_tuple(term) do
    term |> Tuple.to_list() |> canaries_present(canaries)
  end

  defp canaries_present(term, canaries) when is_list(term) do
    Enum.flat_map(term, &canaries_present(&1, canaries))
  end

  defp canaries_present(term, canaries) when is_binary(term) do
    Enum.filter(canaries, &String.contains?(term, &1))
  end

  defp canaries_present(_term, _canaries), do: []
end
