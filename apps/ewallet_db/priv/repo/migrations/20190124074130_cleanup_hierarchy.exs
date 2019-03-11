defmodule EWalletDB.Repo.Migrations.CleanupHierarchy do
  use Ecto.Migration
  import Ecto.Query
  alias EWalletDB.Repo
  alias Ecto.UUID

  def up do
    alter table(:membership) do
      add :key_uuid, references(:key, column: :uuid, type: :uuid)
    end

    create unique_index(:membership, [:key_uuid, :account_uuid])

    alter table(:user) do
      add :global_role, :string
    end

    alter table(:key) do
      add :global_role, :string
      remove :account_uuid
    end

    flush()

    case up_get_master_account_uuid() do
      nil -> nil
      [master_uuid, master_id] ->
        ensure_master_account_setting()

        # give super admin to admins of master account
        give_super_admin_to_master_account_admins(master_uuid)
        give_super_admin_to_all_keys()

        # set master account in settings
        set_master_account_in_settings(master_id)

        # Add memberships for all children accounts
        add_memberships_for_all_children_accounts(master_uuid)

        # global roles for end users and admins
        set_end_users_global_role()
    end

    alter table(:account) do
      remove :parent_uuid
    end
  end

  def down do
    alter table(:account) do
      add :parent_uuid, references(:account, column: :uuid, type: :uuid)
    end

    alter table(:key) do
      add :account_uuid, references(:account, column: :uuid, type: :uuid)
    end

    flush()

    case down_get_master_account_uuid() do
      [master_uuid, _master_id] ->
        # set all account as children of master account (except master, duh!)
        set_all_account_as_master_children(master_uuid)

        # move super admins to master account admin memberships
        add_super_admins_to_master_account(master_uuid)

        # Add master account to keys
        add_master_account_to_keys(master_uuid)

        # remove master account from settings
        remove_master_account_from_settings()

        # remove children memberships
        remove_children_memberships(master_uuid)
      _ ->
        nil
    end

    alter table(:membership) do
      remove :key_uuid
    end

    alter table(:user) do
      remove :global_role, :string
    end

    alter table(:key) do
      remove :global_role, :string
    end
  end

  # This is only ran if the DB already has data, which requires a settings seeding to proceed.
  # Clean DBs won't be impacted.
  defp ensure_master_account_setting do

    if Repo.one(from(s in "setting", select: s.uuid, where: s.key == "master_account")) == nil do
      raise "Run seed for settings before this migration with 'mix seed --settings'"
    end
  end

  defp up_get_master_account_uuid do
    Repo.one(from(a in "account",
             select: [a.uuid, a.id],
             where: is_nil(a.parent_uuid)))
  end

  defp down_get_master_account_uuid do
    data = Repo.one(from(s in "setting",
                        select: s.data,
                        where: s.key == "master_account"))
    case data["value"] do
      nil ->
        Repo.one(from a in "account", select: [a.uuid, a.id], order_by: [asc: a.inserted_at], limit: 1)
      value ->
        Repo.one(from(a in "account",
                 select: [a.uuid, a.id],
                 where: a.id == ^value))
    end
  end

  defp give_super_admin_to_master_account_admins(master_uuid) do
    query = from(m in "membership",
                 select: m.user_uuid,
                 where: m.account_uuid == ^master_uuid)
    user_uuids = Repo.all(query)

    update_query = from(u in "user",
                   where: u.uuid in ^user_uuids and u.is_admin == true,
                   update: [set: [global_role: "super_admin"]])

    Repo.update_all(update_query, [])

    Repo.delete_all(query)
  end

  defp give_super_admin_to_all_keys do
    update_query = from(k in "key", update: [set: [global_role: "super_admin"]])
    Repo.update_all(update_query, [])
  end

  defp set_master_account_in_settings(master_id) do
    data = %{value: master_id}
    update_query = from(s in "setting",
                   where: s.key == "master_account",
                   update: [set: [data: ^data]])

    Repo.update_all(update_query, [])
  end

  defp add_memberships_for_all_children_accounts(master_uuid) do
    descendant_uuids = get_descendant_uuids(master_uuid)
    query = from(m in "membership",
            select: [m.uuid, m.role_uuid, m.user_uuid],
            where: m.account_uuid == ^master_uuid)

    for [_uuid, role_uuid, user_uuid] <- Repo.all(query) do
      Enum.each(descendant_uuids, fn descendant_uuid ->
        insert_membership(user_uuid, role_uuid, descendant_uuid)
      end)
    end
  end

  defp set_end_users_global_role do
    update_query = from(u in "user",
                   where: u.is_admin == false,
                   update: [set: [global_role: "end_user"]])

    Repo.update_all(update_query, [])
  end

  defp set_all_account_as_master_children(master_uuid) do
    update_query = from(a in "account",
                   where: a.uuid != ^master_uuid,
                   update: [set: [parent_uuid: ^master_uuid]])

    Repo.update_all(update_query, [])
  end

  defp add_super_admins_to_master_account(master_uuid) do
    role_uuid = Repo.one(from(r in "role",
                     where: r.name == "admin",
                     select: r.uuid))

    query = from(u in "user",
                 where: u.global_role == "super_admin",
                 select: u.uuid)

    Enum.each(Repo.all(query), fn user_uuid ->
      insert_membership(user_uuid, role_uuid, master_uuid)
    end)
  end

  defp insert_membership(user_uuid, role_uuid, account_uuid) do
    datetime = NaiveDateTime.utc_now()

     {1, nil} = Repo.insert_all "membership", [
          [
            uuid: UUID.bingenerate(),
            role_uuid: role_uuid,
            user_uuid: user_uuid,
            account_uuid: account_uuid,
            inserted_at: datetime,
            updated_at: datetime
          ]
      ]
  end

  defp add_master_account_to_keys(master_uuid) do
    update_query = from(a in "key", update: [set: [account_uuid: ^master_uuid]])

    Repo.update_all(update_query, [])
  end

  defp remove_master_account_from_settings do
    update_query = from(s in "setting",
                   where: s.key == "master_account",
                   update: [set: [data: nil]])

    Repo.update_all(update_query, [])
  end

  defp remove_children_memberships(master_uuid) do
    admin_role_uuid = Repo.one(from(r in "role", where: r.name == "admin", select: r.uuid))

    user_uuids = Repo.all(from(u in "user",
                          where: u.is_admin == true,
                          select: u.uuid))

    query = from(m in "membership",
                 select: [m.user_uuid],
                 where: m.user_uuid in ^user_uuids)

    for [user_uuid] <- Repo.all(query) do
      query = from(m in "membership", select: [m.role_uuid], where: m.user_uuid == ^user_uuid and
                                                                    m.account_uuid == ^master_uuid)

      query
      |> Repo.one()
      |> do_remove_children_memberships(admin_role_uuid, user_uuid, master_uuid)
    end
  end

  defp do_remove_children_memberships(nil, _, _, _), do: nil
  defp do_remove_children_memberships([master_membership_role_uuid], admin_role_uuid, user_uuid, master_uuid) do
    case master_membership_role_uuid == admin_role_uuid do
      true ->
        delete_query = from(m in "membership",
                            where: m.user_uuid == ^user_uuid and m.account_uuid != ^master_uuid,
                            select: m.uuid)

        Repo.delete_all(delete_query)
      false ->
        # only delete membership that have the same role
        delete_query = from(m in "membership",
                            where: m.user_uuid == ^user_uuid and
                                    m.role_uuid == ^master_membership_role_uuid and
                                    m.account_uuid != ^master_uuid,
                            select: m.uuid)

        Repo.delete_all(delete_query)
    end
  end

  defp get_descendant_uuids(master_uuid) do
    {:ok, result} =
      Repo.query(
        "
          WITH RECURSIVE accounts_cte(uuid, id, name, parent_uuid, depth, path) AS (
            SELECT current_account.uuid, current_account.id, current_account.name,
                  current_account.parent_uuid, 0 AS depth, current_account.uuid::TEXT AS path
            FROM account AS current_account WHERE current_account.uuid = $1
          UNION ALL
          SELECT child.uuid, child.id, child.name, child.parent_uuid, parent.depth,
                  (parent.path || '->' || child.uuid::TEXT)
          FROM accounts_cte AS parent, account AS child WHERE child.parent_uuid = parent.uuid
          )
          SELECT DISTINCT * FROM accounts_cte
          ",
        [master_uuid]
      )

    result.rows
    |> Enum.map(fn row -> Enum.at(row, 0) end)
    |> Enum.filter(fn uuid -> uuid != master_uuid end)
  end
end
