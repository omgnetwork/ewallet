defmodule EWalletDB.Repo.Migrations.AddBlockchainStatusToToken do
  use Ecto.Migration

  def change do
    alter table(:token) do
      add :blockchain_status, :string
    end

    create index(:token, [:blockchain_status])
  end
end
