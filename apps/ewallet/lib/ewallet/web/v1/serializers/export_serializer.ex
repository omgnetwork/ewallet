defmodule EWallet.Web.V1.ExportSerializer do
  @moduledoc """
  Serializes exports data into V1 response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Date, Paginator}
  alias EWallet.Web.V1.PaginatorSerializer
  alias Utils.Helpers.Assoc
  alias EWalletDB.Export

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(%Export{} = export) do
    %{
      object: "export",
      id: export.id,
      socket_topic: "export:#{export.id}",
      filename: export.filename,
      schema: export.schema,
      status: export.status,
      completion: export.completion,
      download_url: export.url,
      adapter: export.adapter,
      user_id: Assoc.get(export, [:user, :id]),
      key_id: Assoc.get(export, [:key, :id]),
      params: export.params,
      pid: export.pid,
      created_at: Date.to_iso8601(export.inserted_at),
      updated_at: Date.to_iso8601(export.updated_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil
end
