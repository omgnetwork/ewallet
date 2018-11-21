defmodule EWalletDB.Repo.Migrations.RemoveNullableFromMetadata do
  use Ecto.Migration

  def change do
    alter table(:user) do
      modify :metadata, :map, null: true
    end
  end
end
