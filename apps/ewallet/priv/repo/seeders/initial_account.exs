# This is the seeding script for the master account.
alias EWalletDB.Account

EWallet.CLI.info("\nSeeding the master account...")

master_account_data = %{
  name: "master_account",
  description: "Company Master Account",
  parent_name: nil
}

with nil            <- Account.get_master_account(),
     {:ok, account} <- Account.insert(master_account_data)
do
  EWallet.CLI.success("Master account inserted:\n"
    <> "  Name : #{account.name}\n"
    <> "  ID   : #{account.id}")
else
  %Account{} = account ->
    EWallet.CLI.warn("The master account already exists:\n"
      <> "  Name : #{account.name}\n"
      <> "  ID   : #{account.id}")
  {:error, _} ->
    EWallet.CLI.error("The master account could not be inserted due to an error")
end
