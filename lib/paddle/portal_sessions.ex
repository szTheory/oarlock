defmodule Paddle.PortalSessions do
  @moduledoc """
  Provides the interface for generating customer portal sessions via the Paddle Billing API.
  """

  alias Paddle.Client
  alias Paddle.Http
  alias Paddle.PortalSession
  alias Paddle.Internal.Attrs

  @doc """
  Creates a new customer portal session.

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
          {:ok, Paddle.PortalSession.t()} | {:error, Paddle.Error.t() | :invalid_attrs}
  def create(%Client{} = client, attrs) do
    with {:ok, attrs} <- Attrs.normalize(attrs),
         body <- Attrs.allowlist(attrs, ["customer_id", "subscription_ids"]),
         customer_id <- Map.get(body, "customer_id"),
         {:ok, %{"data" => data}} when is_map(data) <-
           Http.request(client, :post, "/customers/#{customer_id}/portal-sessions",
             json: Map.delete(body, "customer_id")
           ) do
      {:ok, Http.build_struct(PortalSession, data)}
    end
  end
end
