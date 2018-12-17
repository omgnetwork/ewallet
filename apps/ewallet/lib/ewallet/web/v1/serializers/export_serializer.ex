defmodule EWallet.Web.V1.ExportSerializer do
  @moduledoc """
  Serializes exports data into V1 response format.
  """
  alias EWallet.Web.V1.{AccountSerializer, UserSerializer, ExportSerializer}
  alias Utils.Helpers.Assoc
  alias EWalletDB.User

  def serialize(export) do
    %{
      object: "export",
      id: export.id,
      socket_topic: "export:#{export.id}",
      schema: export.schema,
      status: export.status,
      completion: export.completion,
      download_url: nil,
      user_id: Assoc.get(export, [:user, :id]),
      key_id: Assoc.get(export, [:key, :id]),
      params: export.params,
      created_at: Date.to_iso8601(export.inserted_at),
      updated_at: Date.to_iso8601(export.updated_at)
    }
  end
end
