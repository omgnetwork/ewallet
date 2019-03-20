defmodule EWalletDB.Repo.Migrations.DropExchangeAddressAndAccountUuidFromApiKeys do
  use Ecto.Migration
  require Logger

  @table "api_key"

  def up do
    alter table(@table) do
      remove :exchange_address
      Logger.warn("Destructive migration: Column `exchange_address` dropped from `#{@table}`")
      remove :account_uuid
      Logger.warn("Destructive migration: Column `account_uuid` dropped from `#{@table}`")
    end
  end

  def down do
    alter table(@table) do
      add :exchange_address, references(:wallet, type: :string, column: :address)
      add :account_uuid, references(:account, type: :uuid, column: :uuid)
    end
  end
end
