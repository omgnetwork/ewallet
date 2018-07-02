defmodule EWalletDB.Repo.Seeds.APIKeySampleSeed do
  alias EWalletDB.{Account, APIKey}
  alias EWallet.Web.Preloader

  def seed do
    [
      run_banner: "Seeding sample API keys:",
      argsline: [],
    ]
  end

  def run(writer, args) do
    account = Account.get_by(name: "master_account")

    case APIKey.insert(%{account_uuid: account.uuid, owner_app: "ewallet_api"}) do
      {:ok, api_key} ->
        {:ok, api_key} = Preloader.preload_one(api_key, :account)
        writer.success("""
          Owner app    : #{api_key.owner_app}
          Account Name : #{api_key.account.name}
          Account ID   : #{api_key.account.id}
          API key ID   : #{api_key.id}
          API key      : #{api_key.key}
        """)

        args ++ [{:seeded_ewallet_api_key, api_key.key}]
      {:error, changeset} ->
        writer.error("  API key could not be inserted:")
        writer.print_errors(changeset)
      _ ->
        writer.error("  API key could not be inserted:")
        writer.error("  Unknown error.")
    end
  end
end
