defmodule EWalletDB.Repo.Migrations.CreateTransactionRequestConsumption do
  use Ecto.Migration

  def change do
    create table(:transaction_request_consumption, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :amount, :decimal, precision: 81, scale: 0
      add :status, :string, default: "pending", null: false
      add :correlation_id, :string
      add :idempotency_token, :string, null: false
      add :user_id, references(:user, type: :uuid)
      add :transfer_id, references(:transfer, type: :uuid)
      add :transaction_request_id, references(:transaction_request, type: :uuid)
      add :balance_address, references(:balance, type: :string,  column: :address)

      timestamps()
    end

    create unique_index(:transaction_request_consumption, [:correlation_id])
  end
end
