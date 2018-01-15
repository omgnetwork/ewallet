defmodule CaishenMQ.V1.Serializers.Response do
  @moduledoc """
  Serializes data into the default response format.
  """

  def serialize(data, success: success) do
    %{
      success: success,
      data: data
    }
  end
end
