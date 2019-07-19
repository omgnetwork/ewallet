defmodule EWalletDB.Repo.Migrations.CreateHDWallet do
  use Ecto.Migration

  def change do
    create table(:blockchain_hd_wallet, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :keychain_uuid, :uuid, null: false
      add(:blockchain_identifier, :string)

      timestamps()
    end

    create unique_index(:blockchain_hd_wallet, [:keychain_uuid])
  end
end
