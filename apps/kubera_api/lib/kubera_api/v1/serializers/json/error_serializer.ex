defmodule KuberaAPI.V1.JSON.ErrorSerializer do
  @moduledoc """
  Serializes data into V1 JSON response format.
  """
  use KuberaAPI.V1

  def serialize(code, message) do
    %{
      "object" => "error",
      "code" => code,
      "message" => message
    }
  end
end
