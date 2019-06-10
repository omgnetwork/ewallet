defmodule Keychain.Repo.Migrations.AddKeychainTable do
  use Ecto.Migration

  def change do
    create table(:keychain, primary_key: false) do
      add :wallet_id, :string, primary_key: true
      add :encrypted_private_key, :binary, null: false
      timestamps()
    end
  end
end
