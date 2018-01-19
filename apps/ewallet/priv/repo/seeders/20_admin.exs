# This is the seeding script for User (admin & viewer users).

import EWalletDB.Helpers.Crypto, only: [generate_key: 1]

admin_seeds = [
  %{email: "admin01@example.com", password: generate_key(6), metadata: %{}},
  %{email: "admin02@example.com", password: generate_key(6), metadata: %{}},
  %{email: "admin03@example.com", password: generate_key(6), metadata: %{}},
  %{email: "viewer01@example.com", password: generate_key(6), metadata: %{}},
  %{email: "viewer02@example.com", password: generate_key(6), metadata: %{}},
]

memberships = [
  %{email: "admin01@example.com", role_name: "admin", account_name: "brand1"},
  %{email: "admin02@example.com", role_name: "admin", account_name: "region2"},
  %{email: "admin03@example.com", role_name: "admin", account_name: "branch4"},
  %{email: "viewer01@example.com", role_name: "viewer", account_name: "account01"},
  %{email: "viewer02@example.com", role_name: "viewer", account_name: "account02"},
]

EWalletDB.CLI.info("\nSeeding Admin & Viewer (email, password)...")

Enum.each(admin_seeds, fn(data) ->
  with nil <- EWalletDB.User.get_by_email(data.email),
       {:ok, _} <- EWalletDB.User.insert(data)
  do
    EWalletDB.CLI.success("User inserted: #{data.email}, #{data.password}")
  else
    %EWalletDB.User{} ->
      EWalletDB.CLI.warn("User #{data.email} is already in DB")
    {:error, _} ->
      EWalletDB.CLI.error("User #{data.email}" <> " could not be inserted due to an error")
  end
end)

Enum.each(memberships, fn(membership) ->
  with %EWalletDB.User{} = user <- EWalletDB.User.get_by_email(membership.email),
       %EWalletDB.Account{} = account <- EWalletDB.Account.get_by_name(membership.account_name),
       %EWalletDB.Role{} = role <- EWalletDB.Role.get_by_name(membership.role_name),
       {:ok, _} <- EWalletDB.Membership.assign(user, account, role)
  do
    EWalletDB.CLI.success("User assigned: #{user.email}, #{account.name}, #{role.name}")
  else
    _ ->
      EWalletDB.CLI.error("User #{membership.email} could not be assigned due to an error")
  end
end)
