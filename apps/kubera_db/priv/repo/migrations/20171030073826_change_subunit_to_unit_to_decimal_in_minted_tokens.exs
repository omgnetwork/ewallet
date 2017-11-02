defmodule KuberaDB.Repo.Migrations.ChangeSubunitToUnitToDecimalInMintedTokens do
  use Ecto.Migration

  def up do
    alter table(:minted_token) do
      remove :subunit_to_unit
      add :subunit_to_unit, :decimal, precision: 81, scale: 0, null: false
    end
  end

  def down do
    alter table(:minted_token) do
      remove :subunit_to_unit
      add :subunit_to_unit, :integer, null: false
    end
  end
end
