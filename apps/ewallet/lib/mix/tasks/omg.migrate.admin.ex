defmodule Mix.Tasks.Omg.Migrate.Admin do
  @moduledoc """
  Temporary task for migrating admin users.

  ## Examples

  Simply run the following command:

      mix omg.migrate.admin
  """
  import Ecto.Query
  alias Ecto.Changeset
  alias EWalletDB.{Repo, User}

  @start_apps [:logger, :postgrex, :ecto, :ewallet_db]

  def run(_args) do
    Enum.each(@start_apps, &Application.ensure_all_started/1)
    Logger.configure(level: :info)

    User
    |> join(:left, [u], m in assoc(u, :memberships))
    |> where([u, m], not is_nil(m.uuid))
    |> where([u], u.is_admin == false)
    |> select([u], u)
    |> distinct(true)
    |> Repo.all()
    |> migrate()
  end

  defp migrate([]) do
    IO.puts("No users were updated with `is_admin: true`.")
  end

  defp migrate(admins) do
    Repo.transaction(fn -> migrate_each(admins) end)
  end

  defp migrate_each([record | tail]) do
    query =
      User
      |> where(uuid: ^record.uuid)
      |> lock("FOR UPDATE")

    case Repo.one(query) do
      nil ->
        :noop

      user ->
        IO.write("Setting #{user.id} with the email '#{user.email}' to `is_admin: true`... ")

        user
        |> force_changes(:is_admin, true)
        |> Repo.update()

        IO.puts("Done.")
    end

    migrate_each(tail)
  end

  defp migrate_each([]), do: :noop

  defp force_changes(user, field, value) do
    user
    |> Changeset.change()
    |> Changeset.force_change(field, value)
  end
end
