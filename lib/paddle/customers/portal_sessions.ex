defmodule Paddle.Customers.PortalSessions do
  @moduledoc """
  Provides the interface for generating customer portal sessions via the Paddle Billing API.

  Customer portal sessions allow customers to manage their own subscriptions and payment methods.

  ## Example Pipeline

  ```elixir
  client = Paddle.Client.new!(api_key: "sk_test_123")

  case Paddle.Customers.PortalSessions.create(client, "ctm_12345") do
    {:ok, %Paddle.PortalSession{} = session} ->
      IO.puts("Overview URL: \#{session.urls["general"]["overview"]}")

    {:error, :invalid_customer_id} ->
      IO.puts("The provided customer ID was invalid.")

    {:error, %Paddle.Error{} = error} ->
      IO.inspect(error, label: "Paddle API Error")
  end
  ```
  """

  alias Paddle.PortalSession
  alias Paddle.Http
  alias Paddle.Internal.Attrs

  @type customer_id :: String.t()
  @type request_opt :: {:idempotency_key, String.t()} | {:retry, boolean()}

  @create_allowlist ~w(subscription_ids)

  @doc """
  Creates a customer portal session.

  Allows specifying `subscription_ids` to scope the generated portal session URLs.

  ```elixir
  case Paddle.Customers.PortalSessions.create(client, "ctm_12345", subscription_ids: ["sub_123"]) do
    {:ok, %Paddle.PortalSession{} = session} ->
      session
    {:error, %Paddle.Error{} = error} ->
      error
  end
  ```

  ## Errors
  - `{:error, :invalid_customer_id}`: The provided customer ID was not a binary, or was an empty string.
  - `{:error, %Paddle.Error{}}`: A network or API error occurred (e.g. invalid `subscription_ids`).

  ## Related Paddle docs
  https://developer.paddle.com/api-reference/customer-portal/create-portal-session
  """
  @spec create(Paddle.Client.t(), customer_id(), map() | keyword(), [request_opt()]) ::
          {:ok, Paddle.PortalSession.t()}
          | {:error, Paddle.Error.t() | :invalid_customer_id}
  def create(%Paddle.Client{} = client, customer_id, attrs \\ %{}, opts \\ []) do
    with :ok <- validate_customer_id(customer_id),
         {:ok, attrs} <- Attrs.normalize(attrs),
         body <- Attrs.allowlist(attrs, @create_allowlist),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(
             client,
             :post,
             "/customers/#{encode_path_segment(customer_id)}/portal-sessions",
             Keyword.merge([json: body], opts)
           ) do
      {:ok, Http.build_struct(PortalSession, data)}
    end
  end

  defp validate_customer_id(customer_id) when is_binary(customer_id) do
    if String.trim(customer_id) == "" do
      {:error, :invalid_customer_id}
    else
      :ok
    end
  end

  defp validate_customer_id(_), do: {:error, :invalid_customer_id}

  defp encode_path_segment(id), do: URI.encode(id, &URI.char_unreserved?/1)
end
