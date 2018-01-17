defmodule EWalletDB.Repo.Migrations.AddTransferIDToMint do
  use Ecto.Migration

  def change do
    alter table(:mint) do
      add :transfer_id, references(:transfer, type: :uuid)
    end
  end
end
