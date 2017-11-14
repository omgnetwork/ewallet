# This is the seeding script for Account.

seeds = [
  %{name: "account01", description: "Account 1 (Master)", master: true},
  %{name: "account02", description: "Account 2 (Master)", master: true},
  %{name: "account03", description: "Account 3 (Non-Master)", master: false},
  %{name: "account04", description: "Account 4 (Non-Master)", master: false},
]

KuberaDB.CLI.info("\nSeeding Account...")

Enum.each(seeds, fn(data) ->
  with nil <- KuberaDB.Account.get(data.name),
       {:ok, _} <- KuberaDB.Account.insert(data)
  do
    KuberaDB.CLI.success("Account inserted: #{data.name}")
  else
    %KuberaDB.Account{} ->
      KuberaDB.CLI.warn("Account #{data.name} is already in DB")
    {:error, _} ->
      KuberaDB.CLI.error("Account #{data.name}"
        <> " could not be inserted due to an error")
  end
end)
