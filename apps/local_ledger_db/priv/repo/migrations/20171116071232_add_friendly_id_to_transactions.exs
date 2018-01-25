defmodule LocalLedgerDB.Repo.Migrations.AddFriendlyIDToTransactions do
  use Ecto.Migration

  def up do
    alter table(:minted_token) do
      add :friendly_id, :string, null: false
    end
    create unique_index(:minted_token, [:friendly_id])

    alter table(:transaction) do
      remove :minted_token_symbol
      add :minted_token_friendly_id, references(:minted_token, type: :string,
                                                               column: :friendly_id),
                                                               null: false
    end

    flush()

    alter table(:minted_token) do
      remove :symbol
    end
  end

  def down do
    alter table(:minted_token) do
      add :symbol, :string, null: false
    end
    create unique_index(:minted_token, [:symbol])

    alter table(:transaction) do
      remove :minted_token_friendly_id
      add :minted_token_symbol, references(:minted_token, type: :string,
                                                               column: :symbol),
                                                               null: false
    end

    flush()

    alter table(:minted_token) do
      remove :friendly_id
    end
  end
end
