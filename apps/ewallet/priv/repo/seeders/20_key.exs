# This is the seeding script for access & secret keys.

seeds = [
  %{account: EWalletDB.Account.get_by_name("master_account")},
  %{account: EWalletDB.Account.get_by_name("brand1")},
  %{account: EWalletDB.Account.get_by_name("brand2")},
  %{account: EWalletDB.Account.get_by_name("branch1")},
  %{account: EWalletDB.Account.get_by_name("branch2")},
  %{account: EWalletDB.Account.get_by_name("branch3")},
  %{account: EWalletDB.Account.get_by_name("branch4")},
]

EWalletDB.CLI.info("\nSeeding Access/Secret keys (always seed new ones)...")

Enum.each(seeds, fn(data) ->
  case EWalletDB.Key.insert(%{account_id: data.account.id}) do
    {:ok, key} ->
      EWalletDB.CLI.success("📱 Access/Secret keys seeded for #{data.account.name}\n"
        <> "  Access key: #{key.access_key}\n"
        <> "  Secret key: #{key.secret_key}")
    _ ->
      EWalletDB.CLI.error("Access/Secret Keys for #{data.account.name}"
        <> " could not be inserted due to error")
  end
end)
