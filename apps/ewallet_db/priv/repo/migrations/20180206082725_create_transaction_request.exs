defmodule EWalletDB.Repo.Migrations.CreateTransactionRequest do
  use Ecto.Migration

  def change do
    create table(:transaction_request, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :type, :string, null: false
      add :amount, :decimal, precision: 81, scale: 0
      add :status, :string, default: "pending", null: false
      add :correlation_id, :string
      add :user_id, references(:user, type: :uuid)
      add :minted_token_id, references(:minted_token, type: :uuid)
      add :balance_address, references(:balance, type: :string,  column: :address)

      timestamps()
    end

    create unique_index(:transaction_request, [:correlation_id])
  end
end
