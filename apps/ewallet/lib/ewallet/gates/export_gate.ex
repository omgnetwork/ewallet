defmodule EWallet.ExportGate do
  @moduledoc """
  TODO
  """
  alias EWallet.CSVExporter
  alias EWalletDB.{User, Key, Export}

  def generate_url(%{adapter: "aws"} = export) do
    EWallet.S3Exporter.generate_signed_url(export)
  end

  def generate_url(%{adapter: "gcs"} = export) do
    {:ok, ""}
  end

  def generate_url(%{adapter: "local"} = export) do
    {:ok, ""}
  end

  def export(query, schema, serializer, attrs) do
    # generate an export
    with {:ok, export} <- insert_export(schema, attrs),
         {:ok, _pid, export} <- CSVExporter.start(export, schema, query, serializer) do
      {:ok, export}
    else
      error -> error
    end
  end

  defp insert_export(schema, %{originator: %User{} = user} = attrs) do
    attrs
    |> build_attrs(schema, :user_uuid, user)
    |> Export.insert()
  end

  defp insert_export(schema, %{originator: %Key{} = key} = attrs) do
    attrs
    |> build_attrs(schema, :key_uuid, key)
    |> Export.insert()
  end

  defp build_attrs(attrs, schema, owner_key, owner) do
    %{
      schema: schema,
      format: attrs[:export_format] || "csv",
      status: Export.new(),
      completion: 0,
      originator: owner,
      params: Map.delete(attrs, :originator),
    }
    |> Map.put(owner_key, owner.uuid)
  end
end
