defmodule KuberaAPI.V1.JSON.ErrorSerializer do
  @moduledoc """
  Serializes data into V1 JSON response format.
  """
  use KuberaAPI.V1

  def serialize(code, description, messages \\ nil) do
    %{
      object: "error",
      code: code,
      description: description,
      messages: messages
    }
  end
end
