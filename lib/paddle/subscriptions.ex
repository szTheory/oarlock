defmodule Paddle.Subscriptions do
  alias Paddle.Client
  alias Paddle.Http
  alias Paddle.Internal.Attrs
  alias Paddle.Subscription
  alias Paddle.Subscription.ManagementUrls
  alias Paddle.Subscription.ScheduledChange

  @list_allowlist ~w(id customer_id address_id price_id status
                     scheduled_change_action collection_mode
                     next_billed_at order_by after per_page)

  def get(%Client{} = client, subscription_id) do
    with :ok <- validate_subscription_id(subscription_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :get, subscription_path(subscription_id)) do
      {:ok, build_subscription(data)}
    end
  end

  def list(%Client{} = client, params \\ []) do
    with {:ok, params} <- normalize_params(params),
         query <- Attrs.allowlist(params, @list_allowlist),
         {:ok, %{"data" => data, "meta" => meta}} when is_list(data) and is_map(meta) <-
           Http.request(client, :get, "/subscriptions", params: query) do
      {:ok,
       %Paddle.Page{
         data: Enum.map(data, &build_subscription/1),
         meta: meta
       }}
    end
  end

  def cancel(%Client{} = client, subscription_id) do
    do_cancel(client, subscription_id, "next_billing_period")
  end

  def cancel_immediately(%Client{} = client, subscription_id) do
    do_cancel(client, subscription_id, "immediately")
  end

  defp do_cancel(client, subscription_id, effective_from) do
    with :ok <- validate_subscription_id(subscription_id),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(
             client,
             :post,
             cancel_path(subscription_id),
             json: %{"effective_from" => effective_from}
           ) do
      {:ok, build_subscription(data)}
    end
  end

  defp build_subscription(data) when is_map(data) do
    subscription = Http.build_struct(Subscription, data)

    subscription =
      case data["scheduled_change"] do
        sc when is_map(sc) ->
          %{subscription | scheduled_change: Http.build_struct(ScheduledChange, sc)}

        _ ->
          subscription
      end

    case data["management_urls"] do
      mu when is_map(mu) ->
        %{subscription | management_urls: Http.build_struct(ManagementUrls, mu)}

      _ ->
        subscription
    end
  end

  defp validate_subscription_id(id) when is_binary(id) do
    if String.trim(id) == "", do: {:error, :invalid_subscription_id}, else: :ok
  end

  defp validate_subscription_id(_id), do: {:error, :invalid_subscription_id}

  defp normalize_params(params) when is_list(params) do
    if Keyword.keyword?(params) do
      {:ok, params |> Enum.into(%{}) |> Attrs.normalize_keys()}
    else
      {:error, :invalid_params}
    end
  end

  defp normalize_params(params) when is_map(params), do: {:ok, Attrs.normalize_keys(params)}
  defp normalize_params(_params), do: {:error, :invalid_params}

  defp subscription_path(id), do: "/subscriptions/#{encode_path_segment(id)}"
  defp cancel_path(id), do: subscription_path(id) <> "/cancel"

  defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)
end
