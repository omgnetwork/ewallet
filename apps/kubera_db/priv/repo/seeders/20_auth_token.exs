# This is the seeding script for AuthToken.

seeds = [
  # Auth tokens for kubera_api. The users with the given provider_user_id must already be seeded.
  %{user: KuberaDB.User.get_by_provider_user_id("user01"), owner_app: :kubera_api},
  %{user: KuberaDB.User.get_by_provider_user_id("user02"), owner_app: :kubera_api},
  %{user: KuberaDB.User.get_by_provider_user_id("user03"), owner_app: :kubera_api},
  %{user: KuberaDB.User.get_by_provider_user_id("user04"), owner_app: :kubera_api},

  # Auth tokens for kubera_admin. The users with the given email must already be seeded.
  %{user: KuberaDB.User.get_by_email("mercia@example.com"), owner_app: :kubera_admin},
  %{user: KuberaDB.User.get_by_email("spencer@example.com"), owner_app: :kubera_admin},
  %{user: KuberaDB.User.get_by_email("eugene@example.com"), owner_app: :kubera_admin},
  %{user: KuberaDB.User.get_by_email("brian@example.com"), owner_app: :kubera_admin},
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
