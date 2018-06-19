defmodule EWalletDB.Repo.Migrations.CreateExchangePairTable do
  use Ecto.Migration

  def change do
    create table(:exchange_pair, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :id, :string, null: false
      add :name, :string, null: false
      add :from_token_uuid, references(:token, column: :uuid, type: :uuid)
      add :to_token_uuid, references(:token, column: :uuid, type: :uuid)
      add :rate, :float, null: false
      add :reversible, :boolean, null: false

      timestamps()
      add :deleted_at, :naive_datetime
    end

    create unique_index(:exchange_pair, [:id])
  end
end
