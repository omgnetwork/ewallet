defmodule EWalletDB.Repo.Migrations.AddCreatorUserUuidAndCreatorKeyUuidToApiKey do
  use Ecto.Migration

  @table "api_key"

  def change do
    alter table(@table) do
      add :creator_user_uuid, references(:user, type: :uuid, column: :uuid)
      add :creator_key_uuid, references(:key, type: :uuid, column: :uuid)
    end
  end
end
