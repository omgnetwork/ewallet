defmodule CaishenMQ.V1.Serializers.List do
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
