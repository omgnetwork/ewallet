# This is the seeding script for the initial admin panel user.
import EWalletDB.Helpers.Crypto, only: [generate_key: 1]
alias EWallet.{CLI, Seeder}
alias EWalletDB.{Account, Membership, Role, User}

CLI.info("Seeding the Admin Panel's initial user...")

data = %{
  email: "admin_master@example.com",
  password: generate_key(16),
  metadata: %{},
  role_name: "admin"
}

# Insert user
with nil         <- EWalletDB.User.get_by_email(data.email),
     {:ok, user} <- EWalletDB.User.insert(data)
do
  CLI.success("🔧 Admin Panel user inserted:\n"
    <> "  ID       : #{user.id}\n"
    <> "  Email    : #{user.email}\n"
    <> "  Password : #{user.password}\n")
else
  %User{} = user ->
    CLI.warn("🔧 Admin Panel user already exists\n"
      <> "  ID       : #{user.id}\n"
      <> "  Email    : #{user.email}\n"
      <> "  Password : #{user.password || '<hashed>'}\n")
  {:error, changeset} ->
    CLI.error("🔧 Admin Panel user #{data.email} could not be inserted:")
    Seeder.print_errors(changeset)
  _ ->
    CLI.error("🔧 Admin Panel user #{data.email} could not be inserted:")
    CLI.error("  Unable to parse the provided error.\n")
end

# Insert user's membership
with %User{} = user <- User.get_by_email(data.email),
     %Account{} = account <- Account.get_master_account(),
     %Role{} = role <- Role.get_by_name(data.role_name),
     {:ok, _} <- Membership.assign(user, account, role)
do
  CLI.success("🔧 Admin Panel user assigned:\n"
    <> "  Email   : #{user.email}\n"
    <> "  Account : #{account.name}\n"
    <> "  Role    : #{role.name}\n")
else
  {:error, changeset} ->
    CLI.error("🔧 Admin Panel user #{data.email} could not be assigned:")
    Seeder.print_errors(changeset)
  _ ->
    CLI.error("🔧 Admin Panel user #{data.email} could not be assigned:")
    CLI.error("  Unable to parse the provided error.\n")
end
