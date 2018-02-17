# This is the seeding script for Account.
alias EWalletDB.Account

seeds = [
  # Hierarchical accounts:
  # - Company Master Account (top level)
  #   |- Brand 1
  #      |- Branch 1
  #      |- Branch 2
  #   |- Brand 2
  #      |- Branch 3
  #      |- Branch 4

  # Company Master Account
  %{name: "master_account", description: "Company Master Account", parent_name: nil},

  # Brand 1
  %{name: "brand1", description: "Brand 1", parent_name: "master_account"},
  %{name: "branch1", description: "Branch 1", parent_name: "brand1"},
  %{name: "branch2", description: "Branch 2", parent_name: "brand1"},

  # Region 2
  %{name: "brand2", description: "Region 2", parent_name: "master_account"},
  %{name: "branch3", description: "Branch 3", parent_name: "brand2"},
  %{name: "branch4", description: "Branch 4", parent_name: "brand2"},
]

EWalletDB.CLI.info("\nSeeding Account...")

Enum.each(seeds, fn(data) ->
  with nil            <- Account.get_by_name(data.name),
       parent         <- Account.get_by_name(data.parent_name) || %{id: nil},
       data           <- Map.put(data, :parent_id, parent.id),
       {:ok, account} <- Account.insert(data)
  do
    EWalletDB.CLI.success("Account inserted: #{account.name}\n"
      <> "  ID: #{account.id}\n"
      <> "  Parent account: #{account.parent_id}")
  else
    %Account{} = account ->
      EWalletDB.CLI.warn("Account #{account.name} is already in DB")
    {:error, _} ->
      EWalletDB.CLI.error("Account #{data.name}"
        <> " could not be inserted due to an error")
  end
end)
