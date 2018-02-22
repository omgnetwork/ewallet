# This is the seeding script for User (wallet users).
alias EWallet.{CLI, Seeder}
alias EWalletDB.User

CLI.info("Seeding User...")

user_seed = %{
  amount: 20,
  provider_id_prefix: "provider_user_id",
  username_prefix: "user"
}

for n <- 1..user_seed.amount do
  running_string = n |> to_string() |> String.pad_leading(2, "0")
  insert_data = %{
    provider_user_id: user_seed.provider_id_prefix <> running_string,
    username: user_seed.username_prefix <> running_string,
    metadata: %{}
  }

  with nil         <- User.get_by_provider_user_id(insert_data.provider_user_id),
       {:ok, user} <- User.insert(insert_data)
  do
    CLI.success("📱 eWallet User inserted:\n"
      <> "  User ID          : #{user.id}\n"
      <> "  Provider user ID : #{user.provider_user_id}\n"
      <> "  Username         : #{user.username}\n")
  else
    %User{} = user ->
      CLI.warn("📱 eWallet User already exists:\n"
        <> "  User ID          : #{user.id}\n"
        <> "  Provider user ID : #{user.provider_user_id}\n"
        <> "  Username         : #{user.username}\n")
    {:error, changeset} ->
      CLI.error("📱 eWallet User #{insert_data.provider_user_id} could not be inserted:")
      Seeder.print_errors(changeset)
    _ ->
      CLI.error("📱 eWallet User #{insert_data.provider_user_id} could not be inserted:")
      CLI.error("  Unable to parse the provided error.\n")
  end
end
