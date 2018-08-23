defmodule EWalletDB.Repo.Seeds.UserSeed do
  alias EWalletDB.{Account, AccountUser, User}

  @seed_data [
    %{
      email: System.get_env("E2E_TEST_ADMIN_EMAIL") || "test_admin@example.com",
      password: System.get_env("E2E_TEST_ADMIN_PASSWORD") || "password",
      metadata: %{},
      account_name: "master_account",
      is_admin: true
    },
    %{
      email: System.get_env("E2E_TEST_ADMIN_1_EMAIL") || "test_admin_1@example.com",
      password: System.get_env("E2E_TEST_ADMIN_1_PASSWORD") || "password",
      metadata: %{},
      account_name: "master_account",
      is_admin: true
    },
  ]

  def seed do
    [
      run_banner: "Seeding the 2 test admins",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    Enum.each @seed_data, fn data ->
      run_with(writer, data)
    end
  end

  def run_with(writer, data) do
    case User.get_by_email(data.email) do
      nil ->
        case User.insert(data) do
          {:ok, user} ->
            account = Account.get_by(name: data.account_name)
            {:ok, _} = AccountUser.link(account.uuid, user.uuid)

            writer.success("""
              ID       : #{user.id}
              Email    : #{user.email}
              Password : <hidden>
            """)

          {:error, changeset} ->
            writer.error("  Admin Panel user #{data.email} could not be inserted:")
            writer.print_errors(changeset)

          _ ->
            writer.error("  Admin Panel user #{data.email} could not be inserted:")
            writer.error("  Unknown error.")
        end

      %User{} = user ->
        writer.warn("""
          ID       : #{user.id}
          Email    : #{user.email}
          Password : <hidden>
        """)
    end
  end
end
