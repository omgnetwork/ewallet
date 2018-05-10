defmodule EWalletDB.Repo.Seeds.APIKeySeed do
  alias EWalletDB.{Account, APIKey}
  alias EWallet.Web.Preloader

  def seed do
    [
      run_banner: "Seeding an Admin Panel API key",
      argsline: [],
    ]
  end

  def run(writer, args) do
    account = Account.get_master_account()

    data = %{
      account_uuid: account.uuid,
      owner_app: "admin_api",
    }

    case APIKey.insert(data) do
      {:ok, api_key} ->
        api_key = Preloader.preload(api_key, :account)

        writer.success("""
          Account Name : #{api_key.account.name}
          Account ID   : #{api_key.account.id}
          API key ID   : #{api_key.id}
          API key      : #{api_key.key}
        """)

        args ++ [
          {:seeded_admin_api_key, api_key.key},
          {:seeded_admin_api_key_id, api_key.id},
        ]
      {:error, changeset} ->
        writer.error("  Admin Panel API key could not be inserted:")
        writer.print_errors(changeset)
      _ ->
        writer.error("  Admin Panel API key could not be inserted:")
        writer.error("  Unknown error.")
    end
  end
end
