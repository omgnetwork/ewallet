# This is the seeding script for API key.
alias EWalletDB.{Account, APIKey}
alias EWallet.Seeder
alias EWallet.Seeder.CLI

seeds = [
  # Auth tokens for ewallet_api
  %{account_name: "master_account", owner_app: "ewallet_api"},

  # Auth tokens for admin_api
  # Not inserting for master account as it is already seeded in `initial_api_key.exs`
]

CLI.subheading("Seeding API Keys:\n")

Enum.each(seeds, fn(data) ->
  insert_data = %{
    account_id: Account.get_by(name: data.account_name).id,
    owner_app:  data.owner_app
  }

  case APIKey.insert(insert_data) do
    {:ok, api_key} ->
      if data.account_name == "master_account" && data.owner_app == "ewallet_api" do
        Application.put_env(:ewallet, :seed_ewallet_api_key, api_key)
      end
      CLI.success("""
          Owner app  : #{api_key.owner_app}
          Account    : #{data.account_name} (#{api_key.account_id})
          API key ID : #{api_key.id}
          API key    : #{api_key.key}
        """)
    {:error, changeset} ->
      CLI.error("""
          API key could not be inserted:
          Owner app  : #{insert_data.owner_app}
          Account   : #{data.account.name} (#{insert_data.account_id})
        """)
      Seeder.print_errors(changeset)
    _ ->
      CLI.error("  API key could not be inserted:")
      CLI.error("  Unable to parse the provided error.\n")
  end
end)
