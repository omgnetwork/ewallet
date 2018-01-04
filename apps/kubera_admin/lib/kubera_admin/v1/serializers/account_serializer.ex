defmodule KuberaAdmin.V1.AccountSerializer do
  @moduledoc """
  Serializes account(s) into V1 response format.
  """
  alias KuberaAdmin.V1.PaginatorSerializer
  alias Kubera.Web.Paginator

  def to_json(%Paginator{} = paginator) do
    PaginatorSerializer.to_json(paginator, &to_json/1)
  end
  def to_json(account) when is_map(account) do
    %{
      object: "account",
      id: account.id,
      name: account.name,
      description: account.description,
      master: account.master
    }
  end
end
