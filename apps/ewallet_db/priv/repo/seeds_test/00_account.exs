# credo:disable-for-this-file
defmodule EWalletDB.Repo.Seeds.AccountSeed do
  alias EWalletDB.Account

  @seed_data %{
    name: "master_account",
    description: "Master Account",
    parent_id: nil,
  }

  def seed do
    [
      run_banner: "Seeding the master account",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    case Account.get_master_account() do
      nil ->
        case Account.insert(@seed_data) do
          {:ok, account} ->
            writer.success("""
              Name : #{account.name}
              ID   : #{account.id}
            """)
          {:error, changeset} ->
            writer.error("  The master account could not be inserted:")
            writer.print_errors(changeset)
          _ ->
            writer.error("  The master account could not be inserted:")
            writer.error("  Unknown error.")
        end
      %Account{} = account ->
        writer.warn("""
          Name : #{account.name}
          ID   : #{account.id}
        """)
    end
  end
end
