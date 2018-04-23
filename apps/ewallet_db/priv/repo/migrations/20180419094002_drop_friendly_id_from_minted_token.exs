defmodule EWalletDB.Repo.Migrations.DropFriendlyIdFromMintedToken do
  use Ecto.Migration

  def up do
    alter table(:minted_token) do
      remove :friendly_id
    end
  end

  def down do
    alter table(:minted_token) do
      add :friendly_id, :string
    end

    create unique_index(:minted_token, [:friendly_id])
  end
end
