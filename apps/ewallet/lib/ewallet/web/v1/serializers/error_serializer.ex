defmodule EWallet.Web.V1.ErrorSerializer do
  @moduledoc """
  Serializes data into V1 JSON response format.
  """

  def serialize(code, description, messages \\ nil) do
    %{
      object: "error",
      code: code,
      description: description,
      messages: messages
    }
  end
end
