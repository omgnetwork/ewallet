defmodule EWalletDB.Repo.Migrations.AddKeyToMembership do
  use Ecto.Migration

  def change do
    alter table(:membership) do
      add :key_uuid, references(:key, column: :uuid, type: :uuid)
    end

    create unique_index(:membership, [:key_uuid, :account_uuid])
  end
end
