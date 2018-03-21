# This is the seeding script for access & secret keys.
alias EWallet.Seeder
alias EWallet.Seeder.CLI
alias EWalletDB.{Account, Key}

seeds = [
  %{account_name: "master_account"}
]

CLI.subheading("Seeding Access/Secret Keys:\n")

Enum.each(seeds, fn(data) ->
  case Key.insert(%{account_id: Account.get_by(name: data.account_name).id}) do
    {:ok, key} ->
      Application.put_env(:ewallet, :seed_ewallet_key, key)
      CLI.success("""
        Account    : #{data.account_name}
        Access key : #{key.access_key}
        Secret key : #{key.secret_key}
      """)
    {:error, changeset} ->
      CLI.error("  Access/Secret for #{data.account_name} could not be inserted:")
      Seeder.print_errors(changeset)
    _ ->
      CLI.error("  Access/Secret Keys for #{data.account_name} could not be inserted")
      CLI.error("  Unable to parse the provided error.\n")
  end
end)
