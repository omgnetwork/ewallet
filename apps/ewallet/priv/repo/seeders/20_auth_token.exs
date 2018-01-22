# This is the seeding script for AuthToken.

seeds = [
  # Auth tokens for ewallet_api. The users with the given provider_user_id must already be seeded.
  %{user: EWalletDB.User.get_by_provider_user_id("provider_user_id01"), owner_app: :ewallet_api},
  %{user: EWalletDB.User.get_by_provider_user_id("provider_user_id02"), owner_app: :ewallet_api},
  %{user: EWalletDB.User.get_by_provider_user_id("provider_user_id03"), owner_app: :ewallet_api},
  %{user: EWalletDB.User.get_by_provider_user_id("provider_user_id04"), owner_app: :ewallet_api},
  %{user: EWalletDB.User.get_by_provider_user_id("provider_user_id05"), owner_app: :ewallet_api},

  # Auth tokens for admin_api. The users with the given email must already be seeded.
  %{user: EWalletDB.User.get_by_email("admin_master@example.com"), owner_app: :admin_api},
  %{user: EWalletDB.User.get_by_email("admin_brand1@example.com"), owner_app: :admin_api},
  %{user: EWalletDB.User.get_by_email("admin_branch1@example.com"), owner_app: :admin_api},
  %{user: EWalletDB.User.get_by_email("viewer_master@example.com"), owner_app: :admin_api},
  %{user: EWalletDB.User.get_by_email("viewer_brand1@example.com"), owner_app: :admin_api},
  %{user: EWalletDB.User.get_by_email("viewer_branch1@example.com"), owner_app: :admin_api},
]

EWalletDB.CLI.info("\nSeeding AuthToken (always seed new ones)...")

Enum.each(seeds, fn(data) ->
  token =
    data
    |> Map.fetch!(:user)
    |> EWalletDB.AuthToken.generate(data.owner_app)

  case token do
    token when is_binary(token) and byte_size(token) > 0 ->
      EWalletDB.CLI.success("AuthToken seeded for #{data.user.provider_user_id} (for #{data.owner_app})\n"
        <> "  User ID : #{data.user.id}\n"
        <> "  Auth tokens : #{token}")
    _ ->
      EWalletDB.CLI.error("AuthToken for #{data.user.provider_user_id} into #{data.owner_app}"
        <> " could not be inserted due to error")
  end
end)
