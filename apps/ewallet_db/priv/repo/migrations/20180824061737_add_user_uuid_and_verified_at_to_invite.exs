defmodule EWalletDB.Repo.Migrations.AddUserUuidAndVerifiedAtToInvite do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo

  def up do
    alter table(:invite) do
      add :user_uuid, references(:user, column: :uuid, type: :uuid)
      add :verified_at, :naive_datetime
    end

    flush()

    _ = populate_invite_user_uuid()
  end

  def down do
    # Drop any invites that are already verified before dropping the rows
    _ = purge_verified_invites()

    alter table(:invite) do
      remove :user_uuid
      remove :verified_at
    end
  end

  # Private functions

  defp populate_invite_user_uuid do
    query = from(u in "user",
                 select: [u.uuid, u.invite_uuid],
                 where: not is_nil(u.invite_uuid))

    for [user_uuid, invite_uuid] <- Repo.all(query) do
      update_query = from(i in "invite",
                   where: i.uuid == ^invite_uuid,
                   update: [set: [user_uuid: ^user_uuid]])

      Repo.update_all(update_query, [])
    end
  end

  defp purge_verified_invites do
    query = from(i in "invite", where: not is_nil(i.verified_at))
    Repo.delete_all(query)
  end
end
