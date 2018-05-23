defmodule EWallet.Web.V1.PaginatorSerializer do
  @moduledoc """
  Serializes a paginator into V1 response format.
  """
  alias EWallet.Web.Paginator

  @doc """
  Serializes a paginator into a list object in JSON format.
  If a mapper is provided, the paginator's data will be mapped before serialized.
  """
  def serialize(%Paginator{} = paginator, mapper) when is_function(mapper) do
    paginator
    |> Map.update!(:data, fn data -> Enum.map(data, mapper) end)
    |> serialize()
  end

  def serialize(%Paginator{} = paginator) do
    %{
      object: "list",
      data: paginator.data,
      pagination: paginator.pagination
    }
  end
end
