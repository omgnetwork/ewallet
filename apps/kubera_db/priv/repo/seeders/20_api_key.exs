# This is the seeding script for APIKey.

seeds = [
  %{account: KuberaDB.Account.get("account01")},
  %{account: KuberaDB.Account.get("account02")},
  %{account: KuberaDB.Account.get("account03")},
  %{account: KuberaDB.Account.get("account04")},
]

KuberaDB.CLI.info("\nSeeding APIKey (always seed new ones)...")

Enum.each(seeds, fn(data) ->
  case KuberaDB.APIKey.insert(%{account_id: data.account.id}) do
    {:ok, api_key} ->
      KuberaDB.CLI.success("APIKey seeded for #{data.account.name}"
        <> ": #{api_key.key}")
    _ ->
      KuberaDB.CLI.error("APIKey for #{data.account.name}"
        <> " could not be inserted due to error")
  end
end)
