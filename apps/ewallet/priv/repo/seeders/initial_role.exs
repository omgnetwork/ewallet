# This is the seeding script for Role
alias EWallet.{CLI, Seeder}
alias EWalletDB.Role

seeds = [
  %{name: "admin", display_name: "Admin"},
  %{name: "viewer", display_name: "Viewer"}
]

Enum.each(seeds, fn(data) ->
  with nil <- Role.get_by_name(data.name),
       {:ok, _} <- Role.insert(data)
  do
    nil
  else
    %Role{} ->
      nil
    {:error, changeset} ->
      CLI.warn("Role #{data.name} could not be inserted:")
      Seeder.print_errors(changeset)
    _ ->
      CLI.error("Role #{data.name} could not be inserted:")
      CLI.error("  Unable to parse the provided error.\n")
  end
end)
