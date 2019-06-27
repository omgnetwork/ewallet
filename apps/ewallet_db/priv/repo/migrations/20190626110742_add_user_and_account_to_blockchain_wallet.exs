defmodule EWalletDB.Repo.Migrations.AddUserAndAccountToBlockchainWallet do
  use Ecto.Migration

  def change do
    alter table(:blockchain_wallet) do
      add(:user_uuid, references(:user, type: :uuid, column: :uuid))
      add(:account_uuid, references(:account, type: :uuid, column: :uuid))
    end
  end
end
