defmodule EWalletDB.Repo.Migrations.AddDefaultExchangeAddressToApiKeys do
  use Ecto.Migration

  def change do
    alter table(:api_key) do
      add :exchange_address, references(:wallet, type: :string, column: :address)
    end
  end
end
