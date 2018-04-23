# This is the seeding script for API key.
alias EWalletDB.{Account, APIKey}
alias EWallet.Seeder
alias EWallet.Seeder.CLI
alias EWallet.Web.Preloader

seeds = [
  # Auth tokens for ewallet_api
  %{account: Account.get_by(name: "master_account"), owner_app: "ewallet_api"},

  # Auth tokens for admin_api
  # Not inserting for master account as it is already seeded in `initial_api_key.exs`
]

CLI.subheading("Seeding API Keys:\n")

Enum.each(seeds, fn(data) ->
  insert_data = %{
    account_uuid: data.account.uuid,
    owner_app:  data.owner_app
  }

  case APIKey.insert(insert_data) do
    {:ok, api_key} ->
      api_key = Preloader.preload(api_key, :account)
      if data.account.name == "master_account" && data.owner_app == "ewallet_api" do
        Application.put_env(:ewallet, :seed_ewallet_api_key, api_key)
      end
      CLI.success("""
          Owner app  : #{api_key.owner_app}
          Account    : #{api_key.account.name} (#{api_key.account.id})
          API key ID : #{api_key.id}
          API key    : #{api_key.key}
        """)
    {:error, changeset} ->
      CLI.error("""
          API key could not be inserted:
          Owner app : #{insert_data.owner_app}
          Account   : #{data.account.name} (#{data.account.id})
        """)
      Seeder.print_errors(changeset)
    _ ->
      CLI.error("  API key could not be inserted:")
      CLI.error("  Unable to parse the provided error.\n")
  end
end)
