defmodule EWalletDB.Repo.Migrations.AddERC20DeploymentFieldsToToken do
  use Ecto.Migration

  def change do
    alter table(:token) do
      add :tx_hash, :text
      add :blk_number, :integer
      add :contract_uuid, :string
    end

    create index(:token, [:blockchain_identifier, :blk_number])
  end
end
