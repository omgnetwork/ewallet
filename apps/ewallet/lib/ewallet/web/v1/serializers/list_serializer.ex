defmodule EWallet.Web.V1.ListSerializer do
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
