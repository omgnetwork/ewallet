defmodule EWalletDB.Repo.Seeds.AuthTokenSeed do
  alias EWallet.Web.Preloader
  alias EWalletDB.{AuthToken, User, Seeder}

  def seed do
    [
      run_banner: "Seeding auth tokens:",
      argsline: []
    ]
  end

  def run(writer, args) do
    user = User.get_by_email(args[:admin_email])
    owner_app = :admin_api

    case AuthToken.generate(user, owner_app, %Seeder{}) do
      {:ok, token} ->
        {:ok, token} = Preloader.preload_one(token, :user)

        writer.success("""
          Owner app        : #{token.owner_app}
          User ID          : #{token.user.id}
          Provider user ID : #{token.user.provider_user_id || '<not set>'}
          User email       : #{token.user.email || '<not set>'}
          Auth token       : #{token.token}
        """)

        args ++ [{:seeded_admin_auth_token, token.token}]

      {:error, changeset} ->
        writer.error("  Auth token for #{user.id} and #{owner_app} could not be inserted:")
        writer.print_errors(changeset)

      _ ->
        writer.error("  Auth token for #{user.id} and #{owner_app} could not be inserted:")
        writer.error("  Unknown error.")
    end
  end
end
