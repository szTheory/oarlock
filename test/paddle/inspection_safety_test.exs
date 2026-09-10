defmodule Paddle.InspectionSafetyTest do
  use ExUnit.Case, async: true

  alias Paddle.Http
  alias Paddle.NotificationSetting
  alias Paddle.PortalSession

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

  test "source inventory explicitly classifies every public raw_data value" do
    discovered =
      "lib/paddle/**/*.ex"
      |> Path.wildcard()
      |> Enum.reduce(MapSet.new(), fn path, modules ->
        source = File.read!(path)

        if Regex.match?(~r/\b(?:defstruct|defexception)\b[\s\S]*\braw_data\b/, source) do
          [module] = Regex.run(~r/^defmodule\s+([A-Z][A-Za-z0-9_.]*)\s+do/m, source, capture: :all_but_first)
          MapSet.put(modules, module)
        else
          modules
        end
      end)

    assert discovered == MapSet.new(Map.keys(@raw_data_inventory))

    assert Enum.all?(@raw_data_inventory, fn {_module, fields} ->
             is_list(fields) and Enum.uniq(fields) == fields
           end)

    assert Enum.all?(
             Enum.filter(@raw_data_inventory, fn {_module, fields} -> fields != [] end),
             fn {_module, fields} -> :raw_data in fields end
           )
  end

  test "provider-hydrated notification and portal values redact promoted and raw canaries" do
    fixtures = [
      {NotificationSetting,
       %{
         "id" => "ntfset_safe_visible",
         "description" => "Visible notification description",
         "destination" => "https://notify.test/promoted_destination_canary",
         "endpoint_secret_key" => "promoted_endpoint_secret_canary",
         "provider_extension" => %{
           "signed_url" => "https://provider.test/nested_notification_url_canary",
           "credentials" => {"nested_notification_tuple_canary", ["nested_notification_list_canary"]}
         }
       },
       [
         "promoted_destination_canary",
         "promoted_endpoint_secret_canary",
         "nested_notification_url_canary",
         "nested_notification_tuple_canary",
         "nested_notification_list_canary"
       ], [:destination, :endpoint_secret_key, :raw_data], "ntfset_safe_visible"},
      {PortalSession,
       %{
         "id" => "cptrsess_safe_visible",
         "customer_id" => "ctm_safe_visible",
         "urls" => %{
           "general" => %{"overview" => "https://portal.test/promoted_portal_url_canary"}
         },
         "provider_extension" => %{
           "signed_url" => "https://provider.test/nested_portal_url_canary",
           "credentials" => {"nested_portal_tuple_canary", ["nested_portal_list_canary"]}
         }
       },
       [
         "promoted_portal_url_canary",
         "nested_portal_url_canary",
         "nested_portal_tuple_canary",
         "nested_portal_list_canary"
       ], [:urls, :raw_data], "cptrsess_safe_visible"}
    ]

    for {module, payload, canaries, redacted_fields, visible_canary} <- fixtures do
      value = Http.build_struct(module, payload)
      original = value

      assert MapSet.new(canaries_present(value, canaries)) == MapSet.new(canaries)

      rendered = inspect(value)

      assert rendered =~ visible_canary

      for field <- redacted_fields do
        assert rendered =~ ~s(#{field}: "[REDACTED]")
      end

      assert canaries_present(rendered, canaries) == []
      assert value == original
    end
  end

  test "notification and portal inspection is total for empty capability fields" do
    assert is_binary(inspect(%NotificationSetting{}))
    assert is_binary(inspect(%PortalSession{}))
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
