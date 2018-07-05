defmodule EWalletDB.Repo.Migrations.UpdateUniqueIndexOnExchangePair do
  use Ecto.Migration

  def up do
    drop unique_index(:exchange_pair, [:from_token_uuid, :to_token_uuid, :deleted_at])
    create unique_index(:exchange_pair, [:from_token_uuid, :to_token_uuid, :deleted_at], where: "deleted_at IS NOT NULL")
    create unique_index(:exchange_pair, [:from_token_uuid, :to_token_uuid], where: "deleted_at IS NULL")
  end

  def down do
    drop unique_index(:exchange_pair, [:from_token_uuid, :to_token_uuid, :deleted_at], where: "deleted_at IS NOT NULL")
    drop unique_index(:exchange_pair, [:from_token_uuid, :to_token_uuid], where: "deleted_at IS NULL")
    create unique_index(:exchange_pair, [:from_token_uuid, :to_token_uuid, :deleted_at])
  end
end
