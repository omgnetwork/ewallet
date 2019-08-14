defmodule EWalletDB.Repo.Migrations.AddBlkNumberToTransaction do
  use Ecto.Migration

  def change do
    alter table(:transaction) do
      add :blk_number, :integer
    end

    create index(:transaction, [:blockchain_identifier, :blk_number])
  end
end
