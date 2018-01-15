defmodule CaishenDB.Repo.Migrations.AddFriendlyIDToTransactions do
  use Ecto.Migration

  def change do
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
end
