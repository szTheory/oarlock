defmodule Demo.Billing do
  @moduledoc """
  The Billing context.
  """

  import Ecto.Query, warn: false
  alias Demo.Repo

  alias Demo.Billing.WebhookEvent

  @doc """
  Returns the list of webhook_events.

  ## Examples

      iex> list_webhook_events()
      [%WebhookEvent{}, ...]

  """
  def list_webhook_events do
    Repo.all(WebhookEvent)
  end

  @doc """
  Gets a single webhook_event.

  Raises `Ecto.NoResultsError` if the Webhook event does not exist.

  ## Examples

      iex> get_webhook_event!(123)
      %WebhookEvent{}

      iex> get_webhook_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_webhook_event!(id), do: Repo.get!(WebhookEvent, id)

  @doc """
  Creates a webhook_event.

  ## Examples

      iex> create_webhook_event(%{field: value})
      {:ok, %WebhookEvent{}}

      iex> create_webhook_event(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_webhook_event(attrs) do
    %WebhookEvent{}
    |> WebhookEvent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a webhook_event.

  ## Examples

      iex> update_webhook_event(webhook_event, %{field: new_value})
      {:ok, %WebhookEvent{}}

      iex> update_webhook_event(webhook_event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_webhook_event(%WebhookEvent{} = webhook_event, attrs) do
    webhook_event
    |> WebhookEvent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a webhook_event.

  ## Examples

      iex> delete_webhook_event(webhook_event)
      {:ok, %WebhookEvent{}}

      iex> delete_webhook_event(webhook_event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_webhook_event(%WebhookEvent{} = webhook_event) do
    Repo.delete(webhook_event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking webhook_event changes.

  ## Examples

      iex> change_webhook_event(webhook_event)
      %Ecto.Changeset{data: %WebhookEvent{}}

  """
  def change_webhook_event(%WebhookEvent{} = webhook_event, attrs \\ %{}) do
    WebhookEvent.changeset(webhook_event, attrs)
  end

  alias Demo.Billing.Subscription

  @doc """
  Returns the list of subscriptions.

  ## Examples

      iex> list_subscriptions()
      [%Subscription{}, ...]

  """
  def list_subscriptions do
    Repo.all(Subscription)
  end

  @doc """
  Gets a single subscription.

  Raises `Ecto.NoResultsError` if the Subscription does not exist.

  ## Examples

      iex> get_subscription!(123)
      %Subscription{}

      iex> get_subscription!(456)
      ** (Ecto.NoResultsError)

  """
  def get_subscription!(id), do: Repo.get!(Subscription, id)

  @doc """
  Creates a subscription.

  ## Examples

      iex> create_subscription(%{field: value})
      {:ok, %Subscription{}}

      iex> create_subscription(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_subscription(attrs) do
    %Subscription{}
    |> Subscription.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a subscription.

  ## Examples

      iex> update_subscription(subscription, %{field: new_value})
      {:ok, %Subscription{}}

      iex> update_subscription(subscription, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_subscription(%Subscription{} = subscription, attrs) do
    subscription
    |> Subscription.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a subscription.

  ## Examples

      iex> delete_subscription(subscription)
      {:ok, %Subscription{}}

      iex> delete_subscription(subscription)
      {:error, %Ecto.Changeset{}}

  """
  def delete_subscription(%Subscription{} = subscription) do
    Repo.delete(subscription)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking subscription changes.

  ## Examples

      iex> change_subscription(subscription)
      %Ecto.Changeset{data: %Subscription{}}

  """
  def change_subscription(%Subscription{} = subscription, attrs \\ %{}) do
    Subscription.changeset(subscription, attrs)
  end
end
