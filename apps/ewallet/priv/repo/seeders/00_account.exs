# This is the seeding script for Account.

seeds = [
  %{name: "account01", description: "Account 1 (Master)", master: true},
  %{name: "account02", description: "Account 2 (Non-Master)"},
  %{name: "account03", description: "Account 3 (Non-Master)"},
  %{name: "account04", description: "Account 4 (Non-Master)"},
]

EWalletDB.CLI.info("\nSeeding Account...")

Enum.each(seeds, fn(data) ->
  with nil <- EWalletDB.Account.get_by_name(data.name),
       {:ok, _} <- EWalletDB.Account.insert(data)
  do
    EWalletDB.CLI.success("Account inserted: #{data.name}")
  else
    %EWalletDB.Account{} ->
      EWalletDB.CLI.warn("Account #{data.name} is already in DB")
    {:error, _} ->
      EWalletDB.CLI.error("Account #{data.name}"
        <> " could not be inserted due to an error")
  end
end)
