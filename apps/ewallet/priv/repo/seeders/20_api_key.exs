# This is the seeding script for APIKey.

seeds = [
  # Auth tokens for ewallet_api
  %{account: EWalletDB.Account.get_by_name("account01"), owner_app: "ewallet_api"},
  %{account: EWalletDB.Account.get_by_name("account02"), owner_app: "ewallet_api"},
  %{account: EWalletDB.Account.get_by_name("account03"), owner_app: "ewallet_api"},
  %{account: EWalletDB.Account.get_by_name("account04"), owner_app: "ewallet_api"},

  # Auth tokens for admin_api
  %{account: EWalletDB.Account.get_by_name("account01"), owner_app: "admin_api"},
  %{account: EWalletDB.Account.get_by_name("account02"), owner_app: "admin_api"},
  %{account: EWalletDB.Account.get_by_name("account03"), owner_app: "admin_api"},
  %{account: EWalletDB.Account.get_by_name("account04"), owner_app: "admin_api"},
]

EWalletDB.CLI.info("\nSeeding APIKey (always seed new ones)...")

Enum.each(seeds, fn(data) ->
  case EWalletDB.APIKey.insert(%{account_id: data.account.id, owner_app: data.owner_app}) do
    {:ok, api_key} ->
      EWalletDB.CLI.success("APIKey seeded for #{data.account.name} (for #{api_key.owner_app})\n"
        <> "  API key ID: #{api_key.id} \n"
        <> "  API key: #{api_key.key}")
    _ ->
      EWalletDB.CLI.error("APIKey for #{data.account.name} (for #{data.owner_app})"
        <> " could not be inserted due to error")
  end
end)
