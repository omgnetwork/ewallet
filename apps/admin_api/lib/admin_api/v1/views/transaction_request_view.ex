defmodule AdminAPI.V1.TransactionRequestView do
  use AdminAPI, :view

  alias EWallet.Web.V1.{
    ResponseSerializer,
    TransactionRequestSerializer
  }

  def render("transaction_request.json", %{
        transaction_request: transaction_request
      }) do
    transaction_request
    |> TransactionRequestSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
