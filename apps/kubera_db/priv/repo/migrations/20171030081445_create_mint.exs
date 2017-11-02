defmodule KuberaDB.Repo.Migrations.CreateMint do
  use Ecto.Migration

  def change do
    create table(:mint, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :minted_token_id, references(:minted_token, type: :uuid)
      add :description, :text
      add :amount, :decimal, precision: 81, scale: 0, null: false
      add :confirmed, :boolean, null: false, default: false
      timestamps()
    end
  end
end
