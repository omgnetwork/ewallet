# This is the seeding script for User (wallet users).

import KuberaDB.Helpers.Crypto, only: [generate_key: 1]

user_seeds = [
  %{provider_user_id: "user01", username: "arthurdent", metadata: %{}},
  %{provider_user_id: "user02", username: "fordprefect", metadata: %{}},
  %{provider_user_id: "user03", username: "zaphod", metadata: %{}},
  %{provider_user_id: "user04", username: "trillian", metadata: %{}}
]

# provider_user_id and username to be removed in the future as they are not required for admin.
admin_seeds = [
  %{provider_user_id: "user05", username: "mercia", email: "mercia@example.com",
    password: generate_key(6), metadata: %{}},
  %{provider_user_id: "user06", username: "spencer", email: "spencer@example.com",
    password: generate_key(6), metadata: %{}},
  %{provider_user_id: "user07", username: "eugene", email: "eugene@example.com",
    password: generate_key(6), metadata: %{}},
  %{provider_user_id: "user08", username: "brian", email: "brian@example.com",
    password: generate_key(6), metadata: %{}},
]

KuberaDB.CLI.info("\nSeeding User (provider_user_id, username, email, password)...")

Enum.each(user_seeds, fn(data) ->
  with nil <- KuberaDB.User.get_by_provider_user_id(data.provider_user_id),
       {:ok, _} <- KuberaDB.User.insert(data)
  do
    KuberaDB.CLI.success("User inserted: #{data.provider_user_id}, #{data.username}")
  else
    %KuberaDB.User{} ->
      KuberaDB.CLI.warn("User #{data.provider_user_id} is already in DB")
    {:error, _} ->
      KuberaDB.CLI.error("User #{data.provider_user_id}"
        <> " could not be inserted due to an error")
  end
end)

Enum.each(admin_seeds, fn(data) ->
  with nil <- KuberaDB.User.get_by_email(data.email),
       {:ok, _} <- KuberaDB.User.insert(data)
  do
    KuberaDB.CLI.success("User inserted: #{data.email}, #{data.password}")
  else
    %KuberaDB.User{} ->
      KuberaDB.CLI.warn("User #{data.email} is already in DB")
    {:error, changeset} ->
      KuberaDB.CLI.error("User #{data.email}"
        <> " could not be inserted due to an error")
  end
end)
