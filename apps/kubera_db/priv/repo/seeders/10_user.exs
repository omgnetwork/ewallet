# This is the seeding script for User (wallet users).

user_seed = %{amount: 20, provider_id_prefix: "provider_user_id", username_prefix: "user"}

KuberaDB.CLI.info("\nSeeding User (provider_user_id, username)...")

for n <- 1..user_seed.amount do
  running_string = n |> to_string() |> String.pad_leading(2, "0")
  insert_data = %{
    provider_user_id: user_seed.provider_id_prefix <> running_string,
    username: user_seed.username_prefix <> running_string,
    metadata: %{}
  }

  with nil <- KuberaDB.User.get_by_provider_user_id(insert_data.provider_user_id),
       {:ok, _} <- KuberaDB.User.insert(insert_data)
  do
    KuberaDB.CLI.success("User inserted: #{insert_data.provider_user_id}, #{insert_data.username}")
  else
    %KuberaDB.User{} ->
      KuberaDB.CLI.warn("User #{insert_data.provider_user_id} is already in DB")
    {:error, _} ->
      KuberaDB.CLI.error("User #{insert_data.provider_user_id}"
        <> " could not be inserted due to an error")
  end
end
