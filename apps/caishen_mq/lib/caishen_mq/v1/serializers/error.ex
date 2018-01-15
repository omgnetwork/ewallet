defmodule CaishenMQ.V1.Serializers.Error do
  @moduledoc """
  Serializes data into default error format.
  """

  def serialize(code, description) do
    %{
      object:      "error",
      code:        code,
      description: description
    }
  end

  def serialize(code, description, messages) do
    %{
      object:      "error",
      code:        code,
      description: description,
      messages:    messages
    }
  end
end
