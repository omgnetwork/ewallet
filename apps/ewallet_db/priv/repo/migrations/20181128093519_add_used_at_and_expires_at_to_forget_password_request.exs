defmodule EWalletDB.Repo.Migrations.AddUsedAtAndExpiresAtToForgetPasswordRequest do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo

  def up do
    alter table(:forget_password_request) do
      add :used_at, :naive_datetime
      add :expires_at, :naive_datetime
    end

    create index(:forget_password_request, [:enabled, :expires_at])
    flush()

    add_expires_at_to_existing_requests()
  end

  def down do
    expires_past_requests()

    alter table(:forget_password_request) do
      remove :used_at
      remove :expires_at
    end
  end

  # Private functions

  defp add_expires_at_to_existing_requests do
    query = from(f in "forget_password_request",
      update: [
        set: [
          expires_at: fragment("? + '10 minute'::INTERVAL", f.inserted_at)
        ]
      ]
    )

    Repo.update_all(query, [])
  end

  defp expires_past_requests do
    query = from(f in "forget_password_request",
      where: f.enabled == true,
      where: f.expires_at <= ^NaiveDateTime.utc_now(),
      update: [set: [enabled: false]]
    )

    Repo.update_all(query, [])
  end
end
