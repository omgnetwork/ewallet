# This is the seeding script for Role

seeds = [
  %{name: "admin", display_name: "Admin"},
  %{name: "viewer", display_name: "Viewer"}
]

EWalletDB.CLI.info("\nSeeding Role...")

Enum.each(seeds, fn(data) ->
  with nil <- EWalletDB.Role.get_by_name(data.name),
       {:ok, _} <- EWalletDB.Role.insert(data)
  do
    EWalletDB.CLI.success("Role inserted: #{data.name} (#{data.display_name})")
  else
    %EWalletDB.Role{} ->
      EWalletDB.CLI.warn("Role #{data.name} is already in DB")
    {:error, _} ->
      EWalletDB.CLI.error("Role #{data.name}"
        <> " could not be inserted due to an error")
  end
end)
