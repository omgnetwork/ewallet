defmodule EWalletDB.Repo.Seeds.AuthTokenSampleSeed do
  alias EWalletDB.{AuthToken, User}
  alias EWallet.Web.Preloader

  def seed do
    [
      run_banner: "Seeding sample auth tokens:",
      argsline: [],
    ]
  end

  def run(writer, args) do
    user = User.get_by_provider_user_id("provider_user_id01")

    case AuthToken.generate(user, :ewallet_api) do
      {:ok, token} ->
        {:ok, token} = Preloader.preload_one(token, :user)
        writer.success("""
          Owner app        : #{token.owner_app}
          User ID          : #{token.user.id}
          Provider user ID : #{token.user.provider_user_id || '<not set>'}
          User email       : #{token.user.email || '<not set>'}
          Auth token       : #{token.token}
        """)

        args ++ [
          {:seeded_ewallet_user_id, user.id},
          {:seeded_ewallet_auth_token, token.token}
        ]

      {:error, changeset} ->
        writer.error("  Auth token for #{user.id} and ewallet_api could not be inserted:")
        writer.print_errors(changeset)

      _ ->
        writer.error("  Auth token for #{user.id} and ewallet_api could not be inserted:")
        writer.error("  Unknown error.")
    end
  end
end
