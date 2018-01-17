defmodule EWalletDB.Repo.Migrations.EncryptMetadata do
  use Ecto.Migration

  def up do
    alter table(:balance) do
      remove :metadata
      add :metadata, :binary
      add :encryption_version, :binary
    end
    create index(:balance, [:encryption_version])

    alter table(:minted_token) do
      remove :metadata
      add :metadata, :binary
      add :encryption_version, :binary
    end
    create index(:minted_token, [:encryption_version])

    alter table(:user) do
      remove :metadata
      add :metadata, :binary
      add :encryption_version, :binary
    end
    create index(:user, [:encryption_version])
  end

  def down do
    alter table(:balance) do
      remove :metadata
      remove :encryption_version
      add :metadata, :map
    end

    alter table(:minted_token) do
      remove :metadata
      remove :encryption_version
      add :metadata, :map
    end

    alter table(:user) do
      remove :metadata
      remove :encryption_version
      add :metadata, :map
    end
  end
end
