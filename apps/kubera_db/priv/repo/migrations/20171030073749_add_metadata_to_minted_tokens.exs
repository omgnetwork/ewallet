defmodule KuberaDB.Repo.Migrations.AddMetadataToMintedTokens do
  use Ecto.Migration

  def change do
    alter table(:minted_token) do
      add :metadata, :map
    end
  end
end
