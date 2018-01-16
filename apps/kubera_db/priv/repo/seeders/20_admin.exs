# This is the seeding script for User (admin & viewer users).

import KuberaDB.Helpers.Crypto, only: [generate_key: 1]

admin_seeds = [
  %{email: "admin01@example.com", password: generate_key(6), metadata: %{}},
  %{email: "admin02@example.com", password: generate_key(6), metadata: %{}},
  %{email: "admin03@example.com", password: generate_key(6), metadata: %{}},
  %{email: "viewer01@example.com", password: generate_key(6), metadata: %{}},
  %{email: "viewer02@example.com", password: generate_key(6), metadata: %{}},
]

memberships = [
  %{email: "admin01@example.com", role_name: "admin", account_name: "account01"},
  %{email: "admin02@example.com", role_name: "admin", account_name: "account02"},
  %{email: "admin03@example.com", role_name: "admin", account_name: "account03"},
  %{email: "viewer01@example.com", role_name: "viewer", account_name: "account01"},
  %{email: "viewer02@example.com", role_name: "viewer", account_name: "account02"},
]

KuberaDB.CLI.info("\nSeeding Admin & Viewer (email, password)...")

Enum.each(admin_seeds, fn(data) ->
  with nil <- KuberaDB.User.get_by_email(data.email),
       {:ok, _} <- KuberaDB.User.insert(data)
  do
    KuberaDB.CLI.success("User inserted: #{data.email}, #{data.password}")
  else
    %KuberaDB.User{} ->
      KuberaDB.CLI.warn("User #{data.email} is already in DB")
    {:error, _} ->
      KuberaDB.CLI.error("User #{data.email}" <> " could not be inserted due to an error")
  end
end)

Enum.each(memberships, fn(membership) ->
  with %KuberaDB.User{} = user <- KuberaDB.User.get_by_email(membership.email),
       %KuberaDB.Account{} = account <- KuberaDB.Account.get_by_name(membership.account_name),
       %KuberaDB.Role{} = role <- KuberaDB.Role.get_by_name(membership.role_name),
       {:ok, _} <- KuberaDB.Membership.assign(user, account, role)
  do
    KuberaDB.CLI.success("User assigned: #{user.email}, #{account.name}, #{role.name}")
  else
    _ ->
      KuberaDB.CLI.error("User #{membership.email} could not be assigned due to an error")
  end
end)
