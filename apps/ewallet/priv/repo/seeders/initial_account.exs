# This is the seeding script for the master account.
alias EWallet.Seeder
alias EWallet.Seeder.CLI
alias EWalletDB.Account

data = %{
  name: "master_account",
  description: "Master Account",
  parent_id: nil
}

CLI.subheading("Seeding the master account:\n")

with nil            <- Account.get_master_account(),
     {:ok, account} <- Account.insert(data)
do
  CLI.success("""
    Name : #{account.name}
    ID   : #{account.id}
  """)
else
  %Account{} = account ->
    CLI.warn("""
      Name : #{account.name}
      ID   : #{account.id}
    """)
  {:error, changeset} ->
    CLI.error("  The master account could not be inserted:")
    Seeder.print_errors(changeset)
  _ ->
    CLI.error("  The master account could not be inserted:")
    CLI.error("  Unable to parse the provided error.\n")
end
