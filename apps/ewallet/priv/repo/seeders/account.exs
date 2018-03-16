# This is the seeding script for Account.
alias EWallet.Seeder
alias EWallet.Seeder.CLI
alias EWalletDB.Account

seeds = [
  # Hierarchical accounts:
  # - Company Master Account (top level) <- already created in `initial_account.exs`
  #   |- Brand 1
  #      |- Branch 1
  #   |- Brand 2
  #      |- Branch 2

  # Brand 1
  %{name: "brand1", description: "Brand 1", parent_name: "master_account"},
  %{name: "branch1", description: "Branch 1", parent_name: "brand1"},

  # Region 2
  %{name: "brand2", description: "Brand 2", parent_name: "master_account"},
  %{name: "branch2", description: "Branch 2", parent_name: "brand2"},
]

CLI.subheading("Seeding Accounts:\n")

Enum.each(seeds, fn(data) ->
  with nil            <- Account.get_by(name: data.name),
       parent         <- Account.get_by(name: data.parent_name) || %{id: nil},
       data           <- Map.put(data, :parent_id, parent.id),
       {:ok, account} <- Account.insert(data)
  do
    CLI.success("""
      Name   : #{account.name}
      ID     : #{account.id}
      Parent : #{account.parent_id}
    """)
  else
    %Account{} = account ->
      CLI.warn("""
        Name   : #{account.name}
        ID     : #{account.id}
        Parent : #{account.parent_id}
      """)
    {:error, changeset} ->
      CLI.error("  Account #{data.name} could not be inserted due to an error:")
      Seeder.print_errors(changeset)
    _ ->
      CLI.error("  Account #{data.name} could not be inserted due to an error:")
      CLI.error("  Unable to parse the provided error.")
  end
end)
