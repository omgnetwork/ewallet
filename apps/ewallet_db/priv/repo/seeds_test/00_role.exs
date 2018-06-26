# credo:disable-for-this-file
defmodule EWalletDB.Repo.Seeds.RoleSeed do
  alias EWalletDB.Role

  @seed_data [
    %{name: "admin", display_name: "Admin"},
    %{name: "viewer", display_name: "Viewer"},
  ]

  def seed do
    [
      run_banner: "Seeding roles",
      argsline: [],
    ]
  end

  def run(writer, _args) do
    Enum.each @seed_data, fn data ->
      run_with(writer, data)
    end
  end

  defp run_with(writer, data) do
    case Role.get_by_name(data.name) do
      nil ->
        case Role.insert(data) do
          {:ok, role} ->
            writer.success("""
              Name         : #{role.name}
              Display name : #{role.display_name}
            """)
          {:error, changeset} ->
            writer.error("  Role #{data.name} could not be inserted:")
            writer.print_errors(changeset)
          _ ->
            writer.error("  Role #{data.name} could not be inserted:")
            writer.error("  Unknown error.")
        end
      %Role{} = role ->
        writer.warn("""
          Name         : #{role.name}
          Display name : #{role.display_name}
        """)
    end
  end
end
