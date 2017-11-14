# This is the seeding script for User.

seeds = [
  %{provider_user_id: "user01", username: "arthurdent", metadata: %{}},
  %{provider_user_id: "user02", username: "fordprefect", metadata: %{}},
  %{provider_user_id: "user03", username: "zaphodbeeble", metadata: %{}},
  %{provider_user_id: "user04", username: "trillian", metadata: %{}},
]

KuberaDB.CLI.info("\nSeeding User...")

Enum.each(seeds, fn(data) ->
  with nil <- KuberaDB.User.get_by_provider_user_id(data.provider_user_id),
       {:ok, _} <- KuberaDB.User.insert(data)
  do
    KuberaDB.CLI.success("User inserted: #{data.provider_user_id}")
  else
    %KuberaDB.User{} ->
      KuberaDB.CLI.warn("User #{data.provider_user_id} is already in DB")
    {:error, _} ->
      KuberaDB.CLI.error("User #{data.provider_user_id}"
        <> " could not be inserted due to an error")
  end
end)
