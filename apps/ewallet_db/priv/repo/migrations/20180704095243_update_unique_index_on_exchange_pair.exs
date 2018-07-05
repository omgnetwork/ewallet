defmodule EWalletDB.Repo.Migrations.UpdateUniqueIndexOnExchangePair do
  use Ecto.Migration

  def up do
    create unique_index(:exchange_pair, [:from_token_uuid, :to_token_uuid], where: "deleted_at IS NULL")
    drop unique_index(:exchange_pair, [:from_token_uuid, :to_token_uuid, :deleted_at])
  end

  def down do
    create unique_index(:exchange_pair, [:from_token_uuid, :to_token_uuid, :deleted_at])
    drop unique_index(:exchange_pair, [:from_token_uuid, :to_token_uuid], where: "deleted_at IS NULL")
  end
end
