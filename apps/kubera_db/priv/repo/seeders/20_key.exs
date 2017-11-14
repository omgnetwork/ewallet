# This is the seeding script for access & secret keys.

seeds = [
  %{account: KuberaDB.Account.get("account01")},
  %{account: KuberaDB.Account.get("account02")},
  %{account: KuberaDB.Account.get("account03")},
  %{account: KuberaDB.Account.get("account04")},
]

KuberaDB.CLI.info("\nSeeding Access/Secret keys (always seed new ones)...")

Enum.each(seeds, fn(data) ->
  case KuberaDB.Key.insert(%{account_id: data.account.id}) do
    {:ok, api_key} ->
      KuberaDB.CLI.success("Access/Secret keys seeded for #{data.account.name}\n"
        <> "  Access key: #{api_key.access_key}\n"
        <> "  Secret key: #{api_key.secret_key}\n"
        <> "  Base64: " <> Base.encode64(api_key.access_key <> ":" <> api_key.secret_key))
    _ ->
      KuberaDB.CLI.error("Access/Secret Keys for #{data.account.name}"
        <> " could not be inserted due to error")
  end
end)
