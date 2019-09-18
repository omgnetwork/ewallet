defmodule EWalletDB.Repo.Migrations.CreateHDWallet do
  use Ecto.Migration

  def change do
    create table(:blockchain_hd_wallet, primary_key: false) do
      add :uuid, :uuid, primary_key: true
      add :keychain_id, :string, null: false
      add(:blockchain_identifier, :string, null: false)

      timestamps()
    end

    create unique_index(:blockchain_hd_wallet, [:keychain_id])
  end
end
