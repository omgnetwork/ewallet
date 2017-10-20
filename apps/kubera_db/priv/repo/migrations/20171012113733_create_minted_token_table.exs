defmodule KuberaDB.Repo.Migrations.CreateMintedTokenTable do
  use Ecto.Migration

  def change do
    create table(:minted_token, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :symbol, :string, null: false
      add :iso_code, :string
      add :name, :string, null: false
      add :description, :string
      add :short_symbol, :string
      add :subunit, :string
      add :subunit_to_unit, :integer, null: false
      add :symbol_first, :boolean, null: false, default: true
      add :html_entity, :string
      add :iso_numeric, :string
      add :smallest_denomination, :integer
      add :locked, :boolean, default: false

      timestamps()
    end

    create unique_index(:minted_token, [:symbol])
    create unique_index(:minted_token, [:iso_code])
    create unique_index(:minted_token, [:name])
    create unique_index(:minted_token, [:short_symbol])
    create unique_index(:minted_token, [:iso_numeric])
  end
end
