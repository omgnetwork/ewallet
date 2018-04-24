defmodule EWalletDB.Repo.Seeds.UserSeed do
  alias EWalletDB.Helpers.Crypto
  alias EWalletDB.User

  @argsline_desc """
  This email and password combination is required for logging into the admin panel.
  If a user with this email already exists, it will escalate the user to admin role,
  but the password will not be changed.
  """

  def seed do
    [
      run_banner: "Seeding the initial admin panel user",
      argsline: [
        {:title, "What email and password should I set for your first admin user?"},
        {:text, @argsline_desc},
        {:input, {:email, :admin_email, "E-mail", "admin@example.com"}},
        {:input, {:password, :admin_password, "Password", {Crypto, :generate_key, [16]}}},
      ],
    ]
  end

  def run(writer, args) do
    data = %{
      email: args[:admin_email],
      password: args[:admin_password],
      metadata: %{},
    }

    case User.get_by_email(data.email) do
      nil ->
        case User.insert(data) do
          {:ok, user} ->
            writer.success("""
              ID       : #{user.id}
              Email    : #{user.email}
              Password : #{user.password}
            """)

            args ++ [
              {:seeded_admin_user_id, user.id},
              {:seeded_admin_user_email, user.email},
              {:seeded_admin_user_password, user.password},
            ]
          {:error, changeset} ->
            writer.error("  Admin Panel user #{data.email} could not be inserted:")
            writer.print_errors(changeset)
          _ ->
            writer.error("  Admin Panel user #{data.email} could not be inserted:")
            writer.error("  Unknown error.")
        end
      %User{} = user ->
        writer.warn("""
          ID       : #{user.id}
          Email    : #{user.email}
          Password : <hidden>
        """)

        args ++ [
          {:seeded_admin_user_id, user.id},
          {:seeded_admin_user_email, user.email},
          {:seeded_admin_user_password, "<hidden>"},
        ]
    end
  end
end
