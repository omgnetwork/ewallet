defmodule EWalletDB.Repo.Seeds.AdminPanelUserSampleSeed do
  import Utils.Helpers.Crypto, only: [generate_base64_key: 1]
  alias EWalletDB.User
  alias ActivityLogger.System

  @seed_data [
    %{
      email: "admin_brand1@example.com",
      password: generate_base64_key(16),
      metadata: %{},
      is_admin: true,
      originator: %System{}
    },
    %{
      email: "admin_branch1@example.com",
      password: generate_base64_key(16),
      metadata: %{},
      is_admin: true,
      originator: %System{}
    },
    %{
      email: "viewer_master@example.com",
      password: generate_base64_key(16),
      metadata: %{},
      is_admin: true,
      originator: %System{}
    },
    %{
      email: "viewer_brand1@example.com",
      password: generate_base64_key(16),
      metadata: %{},
      is_admin: true,
      originator: %System{}
    },
    %{
      email: "viewer_branch1@example.com",
      password: generate_base64_key(16),
      metadata: %{},
      is_admin: true,
      originator: %System{}
    }
  ]

  def seed do
    [
      run_banner: "Seeding sample admin panel users:",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    Enum.each @seed_data, fn data ->
      run_with(writer, data)
    end
  end

  defp run_with(writer, data) do
    case User.get_by_email(data.email) do
      nil ->
        case User.insert(data) do
          {:ok, user} ->
            writer.success("""
              ID       : #{user.id}
              Email    : #{user.email}
              Password : #{data.password}
            """)
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
    end
  end
end
