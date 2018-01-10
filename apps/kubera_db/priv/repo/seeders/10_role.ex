# This is the seeding script for Role

seeds = [
  %{name: "admin", display_name: "Admin"},
  %{name: "super_admin", display_name: "Super Admin"}
]

KuberaDB.CLI.info("\nSeeding Role...")

Enum.each(seeds, fn(data) ->
  with nil <- KuberaDB.Role.get_by_name(data.name),
       {:ok, _} <- KuberaDB.Role.insert(data)
  do
    KuberaDB.CLI.success("Role inserted: #{data.name} (#{data.display_name})")
  else
    %KuberaDB.Role{} ->
      KuberaDB.CLI.warn("Role #{data.name} is already in DB")
    {:error, _} ->
      KuberaDB.CLI.error("Role #{data.name}"
        <> " could not be inserted due to an error")
  end
end)
