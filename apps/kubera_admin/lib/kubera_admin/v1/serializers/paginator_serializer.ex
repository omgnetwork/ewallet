defmodule KuberaAdmin.V1.PaginatorSerializer do
  @moduledoc """
  Serializes a paginator into V1 response format.
  """
  alias Kubera.Web.Paginator

  @doc """
  Serializes a paginator into a list object in JSON format.
  If a mapper is provided, the paginator's data will be mapped before serialized.
  """
  def to_json(%Paginator{} = paginator, mapper) when is_function(mapper) do
    paginator
    |> Map.update!(:data, fn(data) -> Enum.map(data, mapper) end)
    |> to_json()
  end
  def to_json(%Paginator{} = paginator) do
    %{
      object: "list",
      data: paginator.data,
      pagination: paginator.pagination
    }
  end
end
