defmodule EWalletDB.Repo.Migrations.AddIsAdminToUser do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo

  def up do
    alter table(:user) do
      add :is_admin, :boolean, default: false, null: false
    end

    flush()

    # Get users that have membership
    query = from(m in "membership", distinct: m.user_uuid, select: m.user_uuid)

    # Update those users with memberships with `is_admin: true`
    for user_uuid <- Repo.all(query) do
      update_query = from(u in "user",
                   where: u.uuid == ^user_uuid,
                   update: [set: [is_admin: true]])

      Repo.update_all(update_query, [])
    end
  end

  def down do
    alter table(:user) do
      remove :is_admin
    end
  end
end
