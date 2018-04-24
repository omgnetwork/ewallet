defmodule EWalletDB.Uploaders.Avatar do
  @moduledoc """
  Uploads an avatar after renaming it and transforming it.
  """
  use Arc.Definition
  use Arc.Ecto.Definition

  @acl :public_read
  @versions [:original, :large, :small, :thumb]

  def validate({file, _}) do
    ~w(.jpg .jpeg .gif .png) |> Enum.member?(Path.extname(file.file_name))
  end

  def transform(:large, _) do
    {:convert, "-strip -thumbnail 400x400^ -gravity center -extent 400x400 -format png", :png}
  end

  def transform(:small, _) do
    {:convert, "-strip -thumbnail 150x150^ -gravity center -extent 150x150 -format png", :png}
  end

  def transform(:thumb, _) do
    {:convert, "-strip -thumbnail 50x50^ -gravity center -extent 50x50 -format png", :png}
  end

  def filename(version, _) do
    version
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, scope}) do
    "public/uploads/#{Mix.env()}/#{get_schema_name(scope)}/avatars/#{scope.id}"
  end

  defp get_schema_name(scope) do
    scope.__struct__
    |> Module.split()
    |> Enum.take(-1)
    |> Enum.at(0)
    |> String.downcase()
  end
end
