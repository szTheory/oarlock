defmodule Demo.Billing.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  schema "subscriptions" do
    field :mock_user_id, :string
    field :paddle_customer_id, :string
    field :paddle_subscription_id, :string
    field :status, :string
    field :current_period_end, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:mock_user_id, :paddle_customer_id, :paddle_subscription_id, :status, :current_period_end])
    |> validate_required([:mock_user_id, :paddle_customer_id, :paddle_subscription_id, :status, :current_period_end])
    |> unique_constraint(:mock_user_id)
  end
end
