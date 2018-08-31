defmodule EWalletDB.Repo.Seeds.MembershipSampleSeed do
  alias EWallet.Web.Preloader
  alias EWalletDB.{Account, Membership, Role, User}

  @seed_data [
    %{email: "admin_brand1@example.com", role_name: "admin", account_name: "brand1"},
    %{email: "admin_branch1@example.com", role_name: "admin", account_name: "branch1"},
    %{email: "viewer_master@example.com", role_name: "viewer", account_name: "master_account"},
    %{email: "viewer_brand1@example.com", role_name: "viewer", account_name: "brand1"},
    %{email: "viewer_branch1@example.com", role_name: "viewer", account_name: "branch1"}
  ]

  def seed do
    [
      run_banner: "Seeding sample admin memberships:",
      argsline: []
    ]
  end

  def run(writer, _args) do
    Enum.each(@seed_data, fn data ->
      run_with(writer, data)
    end)
  end

  defp run_with(writer, data) do
    account = Account.get_by(name: data.account_name)
    user = User.get_by_email(data.email)
    role = Role.get_by_name(data.role_name)

    case Membership.get_by_user_and_account(user, account) do
      nil ->
        case Membership.assign(user, account, role) do
          {:ok, membership} ->
            {:ok, membership} = Preloader.preload_one(membership, [:user, :account, :role])

            writer.success("""
              Email        : #{membership.user.email}
              Account Name : #{membership.account.name}
              Account ID   : #{membership.account.id}
              Role         : #{membership.role.name}
            """)

          {:error, changeset} ->
            writer.error("  Admin Panel user #{data.email} could not be assigned:")
            writer.print_errors(changeset)

          _ ->
            writer.error("  Admin Panel user #{data.email} could not be assigned:")
            writer.error("  Unknown error.")
        end

      %Membership{} = membership ->
        {:ok, membership} = Preloader.preload_one(membership, [:user, :account, :role])

        writer.warn("""
          Email        : #{membership.user.email}
          Account Name : #{membership.account.name}
          Account ID   : #{membership.account.id}
          Role         : #{membership.role.name}
        """)
    end
  end
end
