defmodule EWalletDB.Repo.Migrations.AddExternalIdToAccount do
  use Ecto.Migration

  def change do
    alter table(:account) do
      add :external_id, :string
    end

    create index(:account, [:external_id])
  end
end
