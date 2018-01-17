defmodule EWalletDB.Repo.Migrations.AddFriendlyIDToMintedTokens do
  use Ecto.Migration

  def up do
    alter table(:minted_token) do
      add :friendly_id, :string, null: false
    end
    create unique_index(:minted_token, [:friendly_id])
  end

  def down do
    alter table(:minted_token) do
      remove :friendly_id
    end
  end
end
