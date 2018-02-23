# This is the seeding script for the initial API key for setting up the admin panel.
alias EWallet.{CLI, Seeder}
alias EWalletDB.{Account, APIKey}

CLI.info("Seeding the Admin Panel's initial API key (always seed new ones)...")

master  = Account.get_by(name: "master_account")
api_key = APIKey.insert(%{
  account_id: master.id,
  owner_app: "admin_api"
})

case api_key do
  {:ok, api_key} ->
    CLI.success("🔧 Admin Panel API key seeded:\n"
      <> "  Account ID : #{api_key.account_id} \n"
      <> "  API key ID : #{api_key.id} \n"
      <> "  API key    : #{api_key.key}\n")
  {:error, changeset} ->
    CLI.error("🔧 Admin Panel API key could not be inserted:")
    Seeder.print_errors(changeset)
  _ ->
    CLI.error("🔧 Admin Panel API key could not be inserted:")
    CLI.error("  Unable to parse the provided error.\n")
end
