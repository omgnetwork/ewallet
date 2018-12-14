defmodule EWalletDB.Uploaders.File do
  @moduledoc """
  Uploads an avatar after renaming it and transforming it.
  """
  use Arc.Definition
  use Arc.Ecto.Definition

  @acl :private
  @versions [:original]

  def validate({file, _}) do
    ~w(.csv) |> Enum.member?(Path.extname(file.file_name))
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, scope}) do
    "private/uploads/#{Mix.env()}/exports"
  end
end
