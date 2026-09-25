defmodule Demo.Repo.Migrations.CreateWebhookEvents do
  use Ecto.Migration

  def change do
    create table(:webhook_events) do
      add :paddle_event_id, :string
      add :status, :string
      add :raw_data, :map
      add :processed_at, :utc_datetime
      add :error_message, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:webhook_events, [:paddle_event_id])
  end
end
