defmodule KuberaAdmin.V1.ResponseSerializer do
  @moduledoc """
  Serializes data into V1 response format.
  """

  def to_json(data, success: success) do
    %{
      success: success,
      version: "1",
      data: data
    }
  end
end
