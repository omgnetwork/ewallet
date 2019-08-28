defmodule Keychain.Repo.Migrations.AddPubkeyAndUUIDToKey do
  use Ecto.Migration

  def change do
    alter table(:keychain) do
      add :public_key, :string
      add :uuid, :uuid
    end

    create index(:keychain, :public_key)
    create index(:keychain, :uuid)
  end
end
