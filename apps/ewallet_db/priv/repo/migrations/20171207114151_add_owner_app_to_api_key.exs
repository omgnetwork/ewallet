defmodule EWalletDB.Repo.Migrations.AddOwnerAppToApiKeyTable do
  use Ecto.Migration
  alias EWalletDB.Repo

  def up do
    # Add :owner_app without `null: false`, so existing records won't break migration.
    alter table(:api_key) do
      add :owner_app, :string
    end
    create index(:api_key, [:owner_app])
    flush()

    # We don't know for sure which app those tokens belong to before this migration,
    # so it's better to assign all existing tokens as :invalid_app
    Repo.update_all("api_key", set: [owner_app: "invalid_app"])

    # Finally make :owner_app column not-nullable
    alter table(:api_key) do
      modify :owner_app, :string, null: false
    end
  end

  def down do
    # We'll lose the scope of the token after dropping :api_key column.
    # Definitely not wanting a token from a specific app to be usable everywhere else.
    Repo.update_all("api_key", set: [expired: true])

    drop index(:api_key, [:owner_app])
    alter table(:api_key) do
      remove :owner_app
    end
  end
end
