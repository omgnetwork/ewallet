defmodule CaishenDB.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transaction, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :amount, :decimal, precision: 81, scale: 0, null: false
      add :entry_id, references(:entry, type: :uuid), null: false
      add :minted_token_symbol, references(:minted_token, type: :string,
                                                          column: :symbol),
                                null: false
      add :balance_address, references(:balance, type: :string,
                                                 column: :address),
                            null: false
      add :type, :string, null: false
      timestamps()
    end
  end
end
