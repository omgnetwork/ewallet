# This is the seeding script for Role

seeds = [
  %{name: "admin", display_name: "Admin"},
  %{name: "viewer", display_name: "Viewer"}
]

EWallet.CLI.info("\nSeeding Role...")

Enum.each(seeds, fn(data) ->
  with nil <- EWalletDB.Role.get_by_name(data.name),
       {:ok, _} <- EWalletDB.Role.insert(data)
  do
    EWallet.CLI.success("🔧 Role inserted:\n"
      <> "  Name         : #{data.name}\n"
      <> "  Display name : #{data.display_name}")
  else
    %EWalletDB.Role{} ->
      EWallet.CLI.warn("Role #{data.name} is already in DB")
    {:error, _} ->
      EWallet.CLI.error("Role #{data.name}"
        <> " could not be inserted due to an error")
  end
end)
