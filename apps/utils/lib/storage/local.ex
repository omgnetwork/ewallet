defmodule Utils.Storage.Local do
  @moduledoc """
  Modified copy of the Arc local storage, needed to add the base URL before
  the file paths.

  Original: https://github.com/stavro/arc/blob/master/lib/arc/storage/local.ex
  """
  alias Arc.Definition.Versioning
  alias EWalletConfig.Config

  def put(definition, version, {file, scope}) do
    destination_dir = definition.storage_dir(version, {file, scope})

    path =
      Path.join([
        Application.get_env(:ewallet, :root),
        destination_dir,
        file.file_name
      ])

    path |> Path.dirname() |> File.mkdir_p!()

    _ =
      if binary = file.binary do
        File.write!(path, binary)
      else
        File.copy!(file.path, path)
      end

    {:ok, file.file_name}
  end

  def url(definition, version, file_and_scope, _options \\ []) do
    base_url = Config.get("base_url")
    local_path = build_local_path(definition, version, file_and_scope)

    url =
      if String.starts_with?(local_path, "/") do
        base_url <> local_path
      else
        base_url <> "/" <> local_path
      end

    url |> URI.encode()
  end

  def delete(definition, version, file_and_scope) do
    definition
    |> build_local_path(version, file_and_scope)
    |> File.rm()
  end

  defp build_local_path(definition, version, file_and_scope) do
    Path.join([
      definition.storage_dir(version, file_and_scope),
      Versioning.resolve_file_name(definition, version, file_and_scope)
    ])
  end
end
