# This is the seeding script for AuthToken.

seeds = [
  %{user: KuberaDB.User.get_by_provider_user_id("user01")},
  %{user: KuberaDB.User.get_by_provider_user_id("user02")},
  %{user: KuberaDB.User.get_by_provider_user_id("user03")},
  %{user: KuberaDB.User.get_by_provider_user_id("user04")},
]

KuberaDB.CLI.info("\nSeeding AuthToken (always seed new ones)...")

Enum.each(seeds, fn(data) ->
  token =
    data
    |> Map.fetch!(:user)
    |> KuberaDB.AuthToken.generate

  case token do
    token when is_binary(token) and byte_size(token) > 0 ->
      KuberaDB.CLI.success("AuthToken seeded for #{data.user.provider_user_id}"
        <> ": #{token}")
    _ ->
      KuberaDB.CLI.error("AuthToken for #{data.user.provider_user_id}"
        <> " could not be inserted due to error")
  end
end)
