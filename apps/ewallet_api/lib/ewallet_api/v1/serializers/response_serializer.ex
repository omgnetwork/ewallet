defmodule EWalletAPI.V1.ResponseSerializer do
  @moduledoc """
  Serializes data into V1 JSON response format.
  """
  use EWalletAPI.V1

  def serialize(data, success: success) do
    %{
      success: success,
      version: @version,
      data: data
    }
  end
end
