defmodule KuberaDB.Repo.Migrations.AddAccountIdToMintedTokenTable do
  use Ecto.Migration

  def change do
    alter table(:minted_token) do
      add :account_id, references(:account, type: :uuid)
    end
  end
end
