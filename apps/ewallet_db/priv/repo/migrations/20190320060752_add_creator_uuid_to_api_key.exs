defmodule EWalletDB.Repo.Migrations.AddCreatorUuidToApiKey do
  use Ecto.Migration

  @table "api_key"

  def change do
    alter table(@table) do
      add :creator_uuid, references(:user, type: :uuid, column: :uuid)
    end
  end
end
