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
  def to_json(data, success: success, pagination: pagination) do
    %{
      success: success,
      version: "1",
      data: data,
      pagination: %{
        per_page: pagination.per_page,
        current_page: pagination.current_page,
        is_first_page: pagination.is_first_page,
        is_last_page: pagination.is_last_page,
      }
    }
  end
end
