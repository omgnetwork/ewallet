# This is the seeding script for access & secret keys.
alias EWallet.{CLI, Seeder}
alias EWalletDB.{Account, Key}

CLI.info("Seeding Access/Secret keys (always seed new ones)...")

seeds = [
  %{account_name: "master_account"},
  %{account_name: "brand1"},
  %{account_name: "brand2"},
  %{account_name: "branch1"},
  %{account_name: "branch2"},
  %{account_name: "branch3"},
  %{account_name: "branch4"}
]

Enum.each(seeds, fn(data) ->
  case Key.insert(%{account_id: Account.get_by(name: data.account_name).id}) do
    {:ok, key} ->
      CLI.success("📱 Access/Secret keys seeded for #{data.account_name}\n"
        <> "  Access key: #{key.access_key}\n"
        <> "  Secret key: #{key.secret_key}\n")
    {:error, changeset} ->
      CLI.error("📱 Access/Secret for #{data.account_name} could not be inserted:")
      Seeder.print_errors(changeset)
    _ ->
      CLI.error("Access/Secret Keys for #{data.account_name} could not be inserted")
      CLI.error("  Unable to parse the provided error.\n")
  end
end)
