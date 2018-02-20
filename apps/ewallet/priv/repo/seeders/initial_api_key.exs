# This is the seeding script for the initial API key for setting up the admin panel.

EWallet.CLI.info("\nSeeding the Admin Panel's initial API key (always seed new ones)...")

master  = EWalletDB.Account.get_by_name("master_account")
api_key = EWalletDB.APIKey.insert(%{
  account_id: master.id,
  owner_app: "admin_api"
})

case api_key do
  {:ok, api_key} ->
    icon =
      case api_key.owner_app do
        "ewallet_api" -> "📱 "
        "admin_api" -> "🔧 "
        _ -> ""
      end

    EWallet.CLI.success("#{icon}#{api_key.owner_app}: Admin Panel API key seeded:\n"
      <> "  Account ID: #{api_key.account_id} \n"
      <> "  API key ID: #{api_key.id} \n"
      <> "  API key   : #{api_key.key}")
  _ ->
    EWallet.CLI.error("Admin Panel API key could not be inserted due to error")
end
