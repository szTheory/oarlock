defmodule Demo.Repo.Migrations.CreateSubscriptions do
  use Ecto.Migration

  def change do
    create table(:subscriptions) do
      add :mock_user_id, :string
      add :paddle_customer_id, :string
      add :paddle_subscription_id, :string
      add :status, :string
      add :current_period_end, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:subscriptions, [:mock_user_id])
  end
end
