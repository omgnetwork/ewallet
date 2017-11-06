defmodule KuberaAPI.V1.JSON.ListSerializer do
  @moduledoc """
  List serializer used for formatting.
  """

  def serialize(list) do
    %{
      object: "list",
      data: list
    }
  end
end
