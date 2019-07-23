defmodule EWalletDB.Repo.Migrations.CreateBlockchainState do
  use Ecto.Migration

  def change do
    create table(:blockchain_state) do
      add :uuid, :uuid, primary_key: true
      add(:identifier, :string, null: false)
      add(:blk_number, :integer, default: 0, null: false)

      timestamps()
    end

    create unique_index(:blockchain_state, :identifier)
  end
end
