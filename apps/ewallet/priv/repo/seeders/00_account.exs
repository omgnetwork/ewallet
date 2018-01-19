# This is the seeding script for Account.
alias EWalletDB.Account

seeds = [
  # Flat-level accounts
  %{name: "account01", description: "Account 1 (Master)", master: true, parent_name: nil},
  %{name: "account02", description: "Account 2 (Non-Master)", master: false, parent_name: nil},
  %{name: "account03", description: "Account 3 (Non-Master)", master: false, parent_name: nil},
  %{name: "account04", description: "Account 4 (Non-Master)", master: false, parent_name: nil},

  # Hierarchical accounts:
  # Brand 1 (top level)
  # |- Region 1
  #    |- Branch 1
  #    |- Branch 2
  # Brand 2 (top level)
  # |- Region 2
  #    |- Branch 3
  #    |- Branch 4
  %{name: "brand1", description: "Brand 1", master: true, parent_name: nil},
  %{name: "brand2", description: "Brand 2", master: true, parent_name: nil},
  # Region 1
  %{name: "region1", description: "Region 1", master: false, parent_name: "brand1"},
  %{name: "branch1", description: "Branch 1", master: false, parent_name: "region1"},
  %{name: "branch2", description: "Branch 2", master: false, parent_name: "region1"},
  # Region 2
  %{name: "region2", description: "Region 2", master: false, parent_name: "brand2"},
  %{name: "branch3", description: "Branch 3", master: false, parent_name: "region2"},
  %{name: "branch4", description: "Branch 4", master: false, parent_name: "region2"},
]

EWalletDB.CLI.info("\nSeeding Account...")

Enum.each(seeds, fn(data) ->
  with nil <- Account.get_by_name(data.name),
       {:ok, account} <- Account.insert(data)
  do
    EWalletDB.CLI.success("Account inserted: #{data.name}")

    case Account.get_by_name(data.parent_name) do
      nil ->
        EWalletDB.CLI.warn("Did not assign a parent for `#{data.name}`")
      parent ->
        Account.update(account, %{parent_id: parent.id})
    end
  else
    %Account{} ->
      EWalletDB.CLI.warn("Account #{data.name} is already in DB")
    {:error, _} ->
      EWalletDB.CLI.error("Account #{data.name}"
        <> " could not be inserted due to an error")
  end
end)
