# This is the seeding script for Role
alias EWallet.Seeder
alias EWallet.Seeder.CLI
alias EWalletDB.Role

seeds = [
  %{name: "admin", display_name: "Admin"},
  %{name: "viewer", display_name: "Viewer"}
]

CLI.subheading("Seeding roles:\n")

Enum.each(seeds, fn(data) ->
  with nil <- Role.get_by_name(data.name),
       {:ok, _} <- Role.insert(data)
  do
    CLI.success("""
        Name         : #{data.name}
        Display name : #{data.display_name}
      """)
  else
    %Role{} = role ->
      CLI.warn("""
          Name         : #{role.name}
          Display name : #{role.display_name}
        """)
    {:error, changeset} ->
      CLI.warn("  Role #{data.name} could not be inserted:")
      Seeder.print_errors(changeset)
    _ ->
      CLI.error("  Role #{data.name} could not be inserted:")
      CLI.error("  Unable to parse the provided error.\n")
  end
end)
