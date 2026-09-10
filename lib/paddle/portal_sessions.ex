defmodule Paddle.PortalSessions do
  @moduledoc """
  Provides the interface for generating customer portal sessions via the Paddle Billing API.

  This compatibility module delegates to
  `Paddle.Customers.PortalSessions.create/4`, so both entry points share the
  same encoded dispatch path, single-attempt mutation policy, static request
  context, and ambiguity result. Automatic retries and idempotency keys are
  unsupported.
  """

  alias Paddle.Client
  alias Paddle.Customers.PortalSessions, as: CustomerPortalSessions
  alias Paddle.Internal.Attrs

  @doc """
  Creates a new customer portal session.

  This compatibility entry point normalizes the legacy attribute map and then
  delegates to `Paddle.Customers.PortalSessions.create/4`. Ambiguous failures
  are non-retryable and identify `:create_customer_portal_session` plus the
  validated customer resource ID. It does not accept an idempotency option.

  ## Examples

  ```elixir
  case Paddle.PortalSessions.create(client, %{customer_id: "ctm_12345"}) do
    {:ok, %Paddle.PortalSession{} = session} ->
      # Extract the general url
      session.urls["general"]["url"]
  end
  ```
  """
  @spec create(Paddle.Client.t(), map() | keyword()) ::
          {:ok, Paddle.PortalSession.t()}
          | {:error, Paddle.Error.t() | :invalid_attrs | :invalid_customer_id}
  def create(%Client{} = client, attrs) do
    with {:ok, attrs} <- Attrs.normalize(attrs),
         body <- Attrs.allowlist(attrs, ["customer_id", "subscription_ids"]),
         customer_id <- Map.get(body, "customer_id") do
      CustomerPortalSessions.create(client, customer_id, Map.delete(body, "customer_id"))
    end
  end
end
