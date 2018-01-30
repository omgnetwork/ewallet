defmodule EWalletDB.Uploaders.Avatar do
  @moduledoc """
  Uploads an avatar after renaming it and transforming it.
  """
  use Arc.Definition
  use Arc.Ecto.Definition
  alias Ecto.UUID

  @acl      :public_read
  @versions [:original]

  def validate({file, _}) do
    ~w(.jpg .jpeg .gif .png) |> Enum.member?(Path.extname(file.file_name))
  end

  # To add a thumbnail version:
  # @versions [:original, :thumb]

  # Define a thumbnail transformation:
  # def transform(:thumb, _) do
  #   {:convert, "-strip -thumbnail 250x250^ -gravity center -extent 250x250 -format png", :png}
  # end

  def filename(version, _) do
    "#{UUID.generate()}-#{version}"
  end

  # Override the storage directory:
  def storage_dir(_version, {_file, scope}) do
    "public/uploads/#{Mix.env}/#{get_schema_name(scope)}/avatars/#{scope.id}"
  end

  defp get_schema_name(scope) do
    scope.__struct__
    |> Module.split()
    |> Enum.take(-1)
    |> Enum.at(0)
    |> String.downcase()
  end
end
