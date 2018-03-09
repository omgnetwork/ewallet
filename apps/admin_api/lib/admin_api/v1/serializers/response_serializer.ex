defmodule AdminAPI.V1.ResponseSerializer do
  @moduledoc """
  Serializes data into V1 response format.
  """

  @doc """
  Renders the given `data` into a V1 response format as JSON.
  """
  def serialize(data, success: success) do
    %{
      success: success,
      version: "1",
      data: data
    }
  end
end
