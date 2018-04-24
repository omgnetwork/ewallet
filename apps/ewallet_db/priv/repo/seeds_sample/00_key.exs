defmodule EWalletDB.Repo.Seeds.KeySampleSeed do
  alias EWalletDB.{Account, Key}
  alias EWallet.Web.Preloader

  def seed do
    [
      run_banner: "Seeding sample keys:",
      argsline: [],
    ]
  end

  def run(writer, args) do
    account = Account.get_by(name: "master_account")

    case Key.insert(%{account_uuid: account.uuid}) do
      {:ok, key} ->
        key = Preloader.preload(key, :account)
        writer.success("""
          Account Name : #{key.account.name}
          Account ID   : #{key.account.id}
          Access key   : #{key.access_key}
          Secret key   : #{key.secret_key}
        """)

        args ++ [
          {:seeded_ewallet_key_access, key.access_key},
          {:seeded_ewallet_key_secret, key.secret_key},
        ]
      {:error, changeset} ->
        writer.error("  Access/Secret for #{account.name} could not be inserted:")
        writer.print_errors(changeset)
      _ ->
        writer.error("  Access/Secret for #{account.name} could not be inserted:")
        writer.error("  Unknown error.")
    end
  end
end
