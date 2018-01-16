# This is the seeding script for AuthToken.

seeds = [
  # Auth tokens for kubera_api. The users with the given provider_user_id must already be seeded.
  %{user: KuberaDB.User.get_by_provider_user_id("provider_user_id01"), owner_app: :kubera_api},
  %{user: KuberaDB.User.get_by_provider_user_id("provider_user_id02"), owner_app: :kubera_api},
  %{user: KuberaDB.User.get_by_provider_user_id("provider_user_id03"), owner_app: :kubera_api},
  %{user: KuberaDB.User.get_by_provider_user_id("provider_user_id04"), owner_app: :kubera_api},
  %{user: KuberaDB.User.get_by_provider_user_id("provider_user_id05"), owner_app: :kubera_api},

  # Auth tokens for kubera_admin. The users with the given email must already be seeded.
  %{user: KuberaDB.User.get_by_email("admin01@example.com"), owner_app: :kubera_admin},
  %{user: KuberaDB.User.get_by_email("admin02@example.com"), owner_app: :kubera_admin},
  %{user: KuberaDB.User.get_by_email("admin03@example.com"), owner_app: :kubera_admin},
  %{user: KuberaDB.User.get_by_email("viewer01@example.com"), owner_app: :kubera_admin},
  %{user: KuberaDB.User.get_by_email("viewer02@example.com"), owner_app: :kubera_admin},
]

KuberaDB.CLI.info("\nSeeding AuthToken (always seed new ones)...")

Enum.each(seeds, fn(data) ->
  token =
    data
    |> Map.fetch!(:user)
    |> KuberaDB.AuthToken.generate(data.owner_app)

  case token do
    token when is_binary(token) and byte_size(token) > 0 ->
      KuberaDB.CLI.success("AuthToken seeded for #{data.user.provider_user_id} (for #{data.owner_app})\n"
        <> "  User ID : #{data.user.id}\n"
        <> "  Auth tokens : #{token}")
    _ ->
      KuberaDB.CLI.error("AuthToken for #{data.user.provider_user_id} into #{data.owner_app}"
        <> " could not be inserted due to error")
  end
end)
