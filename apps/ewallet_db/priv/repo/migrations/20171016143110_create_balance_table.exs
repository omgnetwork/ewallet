defmodule EWalletDB.Repo.Migrations.CreateBalanceTable do
  use Ecto.Migration

  def change do
    create table(:balance, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :address, :string, null: false
      add :user_id, references(:user, type: :uuid)
      add :minted_token_id, references(:minted_token, type: :uuid)
      add :metadata, :map

      timestamps()
    end

    create unique_index(:balance, [:address])
  end
end
