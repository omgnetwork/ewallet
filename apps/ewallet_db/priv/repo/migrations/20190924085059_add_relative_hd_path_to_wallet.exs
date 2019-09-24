defmodule EWalletDB.Repo.Migrations.AddRelativeHDPathToWallet do
  use Ecto.Migration

  def change do
    alter table(:wallet) do
      add :relative_hd_path, :integer
    end

    create unique_index(:wallet, [:blockchain_identifier, :relative_hd_path])
  end
end
