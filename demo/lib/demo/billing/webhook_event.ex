defmodule Demo.Billing.WebhookEvent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "webhook_events" do
    field :paddle_event_id, :string
    field :status, :string
    field :raw_data, :map
    field :processed_at, :utc_datetime
    field :error_message, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(webhook_event, attrs) do
    webhook_event
    |> cast(attrs, [:paddle_event_id, :status, :raw_data, :processed_at, :error_message])
    |> validate_required([:paddle_event_id, :status, :raw_data])
    |> unique_constraint(:paddle_event_id)
  end
end
