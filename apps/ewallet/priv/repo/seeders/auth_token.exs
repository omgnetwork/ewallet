# This is the seeding script for AuthToken.
alias EWallet.Seeder
alias EWallet.Seeder.CLI
alias EWalletDB.{AuthToken, User}

admin = Application.get_env(:ewallet, :seed_admin_user)

seeds = [
  # Auth tokens for ewallet_api. The users with the given provider_user_id must already be seeded.
  %{user: User.get_by_provider_user_id("provider_user_id01"), owner_app: :ewallet_api},

  # Auth tokens for admin_api. The users with the given email must already be seeded.
  %{user: admin, owner_app: :admin_api},
]

CLI.subheading("Seeding Auth Tokens:\n")

Enum.each(seeds, fn(data) ->
  token =
    data
    |> Map.fetch!(:user)
    |> AuthToken.generate(data.owner_app)

  case token do
    {:ok, token} ->
      cond do
        data.user.provider_user_id == "provider_user_id01" && data.owner_app == :ewallet_api ->
          Application.put_env(:ewallet, :seed_ewallet_auth_token, token)
        data.user.email == admin.email && data.owner_app == :admin_api ->
          Application.put_env(:ewallet, :seed_admin_auth_token, token)
        true ->
          nil
      end
      CLI.success("""
        Owner app        : #{data.owner_app}
        User ID          : #{data.user.id}
        Provider user ID : #{data.user.provider_user_id || '<nil>'}
        User email       : #{data.user.email || '<nil>'}
        Auth token       : #{token.token}
      """)
    {:error, changeset} ->
      CLI.error("""
        AuthToken could not be inserted:
        Owner app        : #{data.owner_app}
        Provider user ID : #{data.user.provider_user_id || '<nil>'}
        User email       : #{data.user.email || '<nil>'}
      """)
      Seeder.print_errors(changeset)
    _ ->
      CLI.error("  AuthToken could not be inserted:")
      CLI.error("  Unable to parse the provided error.\n")
  end
end)
