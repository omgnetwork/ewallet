defmodule EWalletDB.Repo.Migrations.DropOwnerAppFromApiKeys do
  use Ecto.Migration
  require Logger
  import Ecto.Query
  alias EWalletDB.Repo

  @table "api_key"
  @keep_owner_app "ewallet_api"

  def up do
    delete_query = from(t in @table,
                        where: t.owner_app != @keep_owner_app,
                        select: [t.key, t.owner_app])

    {_, deleted} = Repo.delete_all(delete_query)

    for [key, owner_app] <- deleted do
      Logger.warn("Destructive migration: API Key deleted (key: #{key}, owner_app: #{owner_app})")
    end

    alter table(@table) do
      remove :owner_app
    end
  end

  def down do
    alter table(@table) do
      add :owner_app, :string
    end
  end
end
