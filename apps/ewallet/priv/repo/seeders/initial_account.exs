# This is the seeding script for the master account.
alias EWallet.{CLI, Seeder}
alias EWalletDB.Account

data = %{
  name: "master_account",
  description: "Master Account",
  parent_id: nil
}

with nil            <- Account.get_master_account(),
     {:ok, _account} <- Account.insert(data)
do
  nil
else
  %Account{} ->
    nil
  {:error, changeset} ->
    CLI.error("The master account could not be inserted:")
    Seeder.print_errors(changeset)
  _ ->
    CLI.error("The master account could not be inserted:")
    CLI.error("  Unable to parse the provided error.\n")
end
