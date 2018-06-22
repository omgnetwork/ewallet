defmodule EWalletDB.Repo.Seeds.AccountSampleSeed do
  alias EWalletDB.Account
  alias EWallet.Web.Preloader

  @seed_data [
    %{name: "brand1", description: "Brand 1", parent_name: "master_account"},
    %{name: "brand2", description: "Brand 2", parent_name: "master_account"},
    %{name: "branch1", description: "Branch 1", parent_name: "master_account"},
    %{name: "branch2", description: "Branch 2", parent_name: "master_account"},
  ]

  def seed do
    [
      run_banner: "Seeding sample accounts:",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    Enum.each @seed_data, fn data ->
      run_with(writer, data)
    end
  end

  defp run_with(writer, data) do
    parent = Account.get_by(name: data.parent_name)
    data = Map.put(data, :parent_uuid, parent.uuid)

    case Account.get_by(name: data.name) do
      nil ->
        case Account.insert(data) do
          {:ok, account} ->
            {:ok, account} = Preloader.preload_one(account, :parent)
            writer.success("""
              Name   : #{account.name}
              ID     : #{account.id}
              Parent : #{account.parent.id}
            """)
          {:error, changeset} ->
            writer.error("  The account #{data.name} could not be inserted:")
            writer.print_errors(changeset)
          _ ->
            writer.error("  The account #{data.name} could not be inserted:")
            writer.error("  Unknown error.")
        end
      %Account{} = account ->
        {:ok, account} = Preloader.preload_one(account, :parent)
        writer.warn("""
          Name   : #{account.name}
          ID     : #{account.id}
          Parent : #{account.parent.id}
        """)
    end
  end
end
