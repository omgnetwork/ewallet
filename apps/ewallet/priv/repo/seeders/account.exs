# This is the seeding script for Account.
alias EWallet.{CLI, Seeder}
alias EWalletDB.Account

CLI.info("Seeding Account...")

seeds = [
  # Hierarchical accounts:
  # - Company Master Account (top level)
  #   |- Brand 1
  #      |- Branch 1
  #      |- Branch 2
  #   |- Brand 2
  #      |- Branch 3
  #      |- Branch 4

  # Brand 1
  %{name: "brand1", description: "Brand 1", parent_name: "master_account"},
  %{name: "branch1", description: "Branch 1", parent_name: "brand1"},
  %{name: "branch2", description: "Branch 2", parent_name: "brand1"},

  # Region 2
  %{name: "brand2", description: "Region 2", parent_name: "master_account"},
  %{name: "branch3", description: "Branch 3", parent_name: "brand2"},
  %{name: "branch4", description: "Branch 4", parent_name: "brand2"},
]

Enum.each(seeds, fn(data) ->
  with nil            <- Account.get_by(name: data.name),
       parent         <- Account.get_by(name: data.parent_name) || %{id: nil},
       data           <- Map.put(data, :parent_id, parent.id),
       {:ok, account} <- Account.insert(data)
  do
    CLI.success("Account inserted:\n"
      <> "  Name   : #{account.name}\n"
      <> "  ID     : #{account.id}\n"
      <> "  Parent : #{account.parent_id}\n")
  else
    %Account{} = account ->
      CLI.warn("Account already exists:\n"
        <> "  Name   : #{account.name}\n"
        <> "  ID     : #{account.id}\n"
        <> "  Parent : #{account.parent_id}\n")
    {:error, changeset} ->
      CLI.error("Account #{data.name} could not be inserted due to an error:")
      Seeder.print_errors(changeset)
    _ ->
      CLI.error("Account #{data.name} could not be inserted due to an error:")
      CLI.error("  Unable to parse the provided error.")
  end
end)
