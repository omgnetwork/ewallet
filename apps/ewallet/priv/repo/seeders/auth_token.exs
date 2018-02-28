# This is the seeding script for AuthToken.
alias EWallet.{CLI, Seeder}
alias EWalletDB.{AuthToken, User}

seeds = [
  # Auth tokens for ewallet_api. The users with the given provider_user_id must already be seeded.
  %{user: User.get_by_provider_user_id("provider_user_id01"), owner_app: :ewallet_api},
  %{user: User.get_by_provider_user_id("provider_user_id02"), owner_app: :ewallet_api},
  %{user: User.get_by_provider_user_id("provider_user_id03"), owner_app: :ewallet_api},
  %{user: User.get_by_provider_user_id("provider_user_id04"), owner_app: :ewallet_api},
  %{user: User.get_by_provider_user_id("provider_user_id05"), owner_app: :ewallet_api},

  # Auth tokens for admin_api. The users with the given email must already be seeded.
  %{user: User.get_by_email("admin_master@example.com"), owner_app: :admin_api},
  %{user: User.get_by_email("admin_brand1@example.com"), owner_app: :admin_api},
  %{user: User.get_by_email("admin_branch1@example.com"), owner_app: :admin_api},
  %{user: User.get_by_email("viewer_master@example.com"), owner_app: :admin_api},
  %{user: User.get_by_email("viewer_brand1@example.com"), owner_app: :admin_api},
  %{user: User.get_by_email("viewer_branch1@example.com"), owner_app: :admin_api},
]

Enum.each(seeds, fn(data) ->
  token =
    data
    |> Map.fetch!(:user)
    |> AuthToken.generate(data.owner_app)

  icon =
    case data.owner_app do
      :ewallet_api -> "📱 "
      :admin_api   -> "🔧 "
      _            -> ""
    end

  case token do
    {:ok, token} ->
      cond do
        data.user.provider_user_id == "provider_user_id01" && data.owner_app == :ewallet_api ->
          Application.put_env(:ewallet, :seed_ewallet_auth_token, token)
        data.user.email == "admin_master@example.com" && data.owner_app == :admin_api ->
          Application.put_env(:ewallet, :seed_admin_auth_token, token)
        true ->
          nil
      end
    {:error, changeset} ->
      CLI.error("#{icon} AuthToken could not be inserted:"
        <> "  Owner app        : #{data.owner_app}\n"
        <> "  Provider user ID : #{data.user.provider_user_id || '<nil>'}\n"
        <> "  User email       : #{data.user.email || '<nil>'}\n")
      Seeder.print_errors(changeset)
    _ ->
      CLI.error("#{icon} AuthToken could not be inserted:")
      CLI.error("  Unable to parse the provided error.\n")
  end
end)
