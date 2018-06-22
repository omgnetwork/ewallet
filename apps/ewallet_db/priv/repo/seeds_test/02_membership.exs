defmodule EWalletDB.Repo.Seeds.MembershipSeed do
  alias EWalletDB.{Account, Membership, Role, User}
  alias EWallet.Web.Preloader

  @seed_data %{
    admin_email: System.get_env("E2E_TEST_ADMIN_EMAIL") || "test_admin@example.com",
  }

  def seed do
    [
      run_banner: "Seeding the admin membership",
      argsline: [],
    ]
  end

  def run(writer, args) do
    admin_email = @seed_data[:admin_email]

    user = User.get_by_email(admin_email)
    account = Account.get_master_account()
    role = Role.get_by_name("admin")

    case Membership.get_by_user_and_account(user, account) do
      nil ->
        case Membership.assign(user, account, role) do
        {:ok, membership} ->
            membership = Preloader.preload(membership, [:user, :account, :role])
            writer.success("""
              Email        : #{membership.user.email}
              Account Name : #{membership.account.name}
              Account ID   : #{membership.account.id}
              Role         : #{membership.role.name}
            """)
        {:error, changeset} ->
            writer.error("  Admin Panel user #{admin_email} could not be assigned:")
            writer.print_errors(changeset)
        _ ->
            writer.error("  Admin Panel user #{admin_email} could not be assigned:")
            writer.error("  Unknown error.")
        end
      %Membership{} = membership ->
        membership = Preloader.preload(membership, [:user, :account, :role])
        writer.warn("""
          Email        : #{membership.user.email}
          Account Name : #{membership.account.name}
          Account ID   : #{membership.account.id}
          Role         : #{membership.role.name}
        """)
    end
  end
end
