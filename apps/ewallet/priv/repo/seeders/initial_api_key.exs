# This is the seeding script for the initial API key for setting up the admin panel.
alias EWallet.{CLI, Seeder}
alias EWalletDB.{Account, APIKey}

master  = Account.get_by(name: "master_account")
api_key = APIKey.insert(%{
  account_id: master.id,
  owner_app: "admin_api"
})

case api_key do
  {:ok, api_key} ->
    Application.put_env(:ewallet, :seed_admin_api_key, api_key)
  {:error, changeset} ->
    CLI.error("🔧 Admin Panel API key could not be inserted:")
    Seeder.print_errors(changeset)
  _ ->
    CLI.error("🔧 Admin Panel API key could not be inserted:")
    CLI.error("  Unable to parse the provided error.\n")
end
