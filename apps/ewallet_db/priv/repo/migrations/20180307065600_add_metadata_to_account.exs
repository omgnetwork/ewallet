defmodule EWalletDB.Repo.Migrations.AddMetadataToAccount do
  use Ecto.Migration

  def change do
    alter table(:account) do
      add :metadata, :map
      add :encrypted_metadata, :binary
      add :encryption_version, :binary
    end

    create index(:account, [:metadata], using: "gin")
    create index(:account, [:encryption_version])
  end
end
