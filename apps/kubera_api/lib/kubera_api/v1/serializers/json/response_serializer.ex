defmodule KuberaAPI.V1.JSON.ResponseSerializer do
  @moduledoc """
  Serializes data into V1 JSON response format.
  """
  use KuberaAPI.V1

  def serialize(data, success: success) do
    %{
      success: success,
      version: @version,
      data: data
    }
  end
end
