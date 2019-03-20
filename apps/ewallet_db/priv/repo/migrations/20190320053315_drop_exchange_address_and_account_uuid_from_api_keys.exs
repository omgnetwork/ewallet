defmodule EWalletDB.Repo.Migrations.DropExchangeAddressAndAccountUuidFromApiKeys do
  use Ecto.Migration
  require Logger

  @table "api_key"

  def up do
    alter table(@table) do
      remove :exchange_address
      remove :account_uuid
    end
  end

  def down do
    alter table(@table) do
      add :exchange_address, references(:wallet, type: :string, column: :address)
      add :account_uuid, references(:account, type: :uuid, column: :uuid)
    end
  end
end
