# This is the seeding script for the initial admin panel user.
import EWalletDB.Helpers.Crypto, only: [generate_key: 1]
alias EWallet.Seeder
alias EWallet.Seeder.CLI
alias EWalletDB.{Account, Membership, Role, User}

data = %{
  email: Application.get_env(:ewallet, :seed_admin_email),
  password: generate_key(16),
  metadata: %{},
  role_name: "admin"
}

CLI.subheading("Seeding the initial admin panel user:\n")

# Insert user
with nil         <- EWalletDB.User.get_by_email(data.email),
     {:ok, user} <- EWalletDB.User.insert(data)
do
  Application.put_env(:ewallet, :seed_admin_user, user)
  CLI.success("""
    ID       : #{user.id}
    Email    : #{user.email}
    Password : #{user.password}
  """)
else
  %User{} = user ->
    Application.put_env(:ewallet, :seed_admin_user, user)
    CLI.warn("""
      ID       : #{user.id}
      Email    : #{user.email}
      Password : #{user.password || '<hashed>'}
    """)
  {:error, changeset} ->
    CLI.error("  Admin Panel user #{data.email} could not be inserted:")
    Seeder.print_errors(changeset)
  _ ->
    CLI.error("  Admin Panel user #{data.email} could not be inserted:")
    CLI.error("  Unable to parse the provided error.\n")
end

# Insert user's membership
with %User{} = user <- User.get_by_email(data.email),
     %Account{} = account <- Account.get_master_account(),
     %Role{} = role <- Role.get_by_name(data.role_name),
     {:ok, _} <- Membership.assign(user, account, role)
do
  CLI.success("""
      Email   : #{user.email}
      Account : #{account.name}
      Role    : #{role.name}
    """)
else
  {:error, changeset} ->
    CLI.error("  Admin Panel user #{data.email} could not be assigned:")
    Seeder.print_errors(changeset)
  _ ->
    CLI.error("  Admin Panel user #{data.email} could not be assigned:")
    CLI.error("  Unable to parse the provided error.\n")
end
