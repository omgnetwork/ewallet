# This is the seeding script for the initial admin panel user.

EWallet.CLI.info("\nSeeding the Admin Panel's initial user...")

import EWalletDB.Helpers.Crypto, only: [generate_key: 1]

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
  EWallet.CLI.success("🔧 Admin Panel user inserted:\n"
    <> "  ID       : #{user.id}\n"
    <> "  Email    : #{user.email}\n"
    <> "  Password : #{user.password}")
else
  %EWalletDB.User{} ->
    EWallet.CLI.warn("🔧 Admin Panel user #{data.email} already exists")
  {:error, _} ->
    EWallet.CLI.error("🔧 Admin Panel user #{data.email} could not be inserted due to an error")
end

# Insert user's membership
with %EWalletDB.User{} = user <- EWalletDB.User.get_by_email(data.email),
     %EWalletDB.Account{} = account <- EWalletDB.Account.get_master_account(),
     %EWalletDB.Role{} = role <- EWalletDB.Role.get_by_name(data.role_name),
     {:ok, _} <- EWalletDB.Membership.assign(user, account, role)
do
  EWallet.CLI.success("🔧 Admin Panel user assigned:\n"
    <> "  Email   : #{user.email}\n"
    <> "  Account : #{account.name}\n"
    <> "  Role    : #{role.name}")
else
  _ ->
    EWallet.CLI.error("🔧 Admin Panel user #{data.email}"
      <> " could not be assigned due to an error")
end
