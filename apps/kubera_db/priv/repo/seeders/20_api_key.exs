# This is the seeding script for APIKey.

seeds = [
  # Auth tokens for kubera_api
  %{account: KuberaDB.Account.get_by_name("account01"), owner_app: "kubera_api"},
  %{account: KuberaDB.Account.get_by_name("account02"), owner_app: "kubera_api"},
  %{account: KuberaDB.Account.get_by_name("account03"), owner_app: "kubera_api"},
  %{account: KuberaDB.Account.get_by_name("account04"), owner_app: "kubera_api"},

  # Auth tokens for kubera_admin
  %{account: KuberaDB.Account.get_by_name("account01"), owner_app: "kubera_admin"},
  %{account: KuberaDB.Account.get_by_name("account02"), owner_app: "kubera_admin"},
  %{account: KuberaDB.Account.get_by_name("account03"), owner_app: "kubera_admin"},
  %{account: KuberaDB.Account.get_by_name("account04"), owner_app: "kubera_admin"},
]

KuberaDB.CLI.info("\nSeeding APIKey (always seed new ones)...")

Enum.each(seeds, fn(data) ->
  case KuberaDB.APIKey.insert(%{account_id: data.account.id, owner_app: data.owner_app}) do
    {:ok, api_key} ->
      KuberaDB.CLI.success("APIKey seeded for #{data.account.name} (for #{api_key.owner_app})\n"
        <> "  API key ID: #{api_key.id} \n"
        <> "  API key: #{api_key.key}")
    _ ->
      KuberaDB.CLI.error("APIKey for #{data.account.name} (for #{data.owner_app})"
        <> " could not be inserted due to error")
  end
end)
