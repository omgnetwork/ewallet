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

CLI.info("Seeding AuthToken (always seed new ones)...")

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
      CLI.success("#{icon} AuthToken seeded:\n"
        <> "  Owner app        : #{data.owner_app}\n"
        <> "  User ID          : #{data.user.id}\n"
        <> "  Provider user ID : #{data.user.provider_user_id || '<nil>'}\n"
        <> "  User email       : #{data.user.email || '<nil>'}\n"
        <> "  Auth token       : #{token}\n")
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
