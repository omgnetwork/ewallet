# This is the seeding script for the master account.
alias EWallet.{CLI, Seeder}
alias EWalletDB.Account

CLI.info("Seeding the master account...")

data = %{
  name: "master_account",
  description: "Master Account",
  parent_id: nil
}

with nil            <- Account.get_master_account(),
     {:ok, account} <- Account.insert(data)
do
  CLI.success("Master account inserted:\n"
    <> "  Name : #{account.name}\n"
    <> "  ID   : #{account.id}\n")
else
  %Account{} = account ->
    CLI.warn("The master account already exists:\n"
      <> "  Name : #{account.name}\n"
      <> "  ID   : #{account.id}\n")
  {:error, changeset} ->
    CLI.error("The master account could not be inserted:")
    Seeder.print_errors(changeset)
  _ ->
    CLI.error("The master account could not be inserted:")
    CLI.error("  Unable to parse the provided error.\n")
end
