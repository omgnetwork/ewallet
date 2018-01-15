defmodule CaishenDB.Repo.Migrations.CreateMintedTokens do
  use Ecto.Migration

  def change do
    create table(:minted_token, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :symbol, :string, null: false
      add :metadata, :binary
      add :encryption_version, :binary
      timestamps()
    end

    create unique_index(:minted_token, [:symbol])
    create index(:minted_token, [:encryption_version])
  end
end
