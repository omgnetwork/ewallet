defmodule EWalletAPI.V1.TransactionView do
  use EWalletAPI, :view
  alias EWallet.Web.V1.{
    ResponseSerializer,
    TransactionSerializer
  }

  def render("transaction.json", %{transaction: transaction}) do
    transaction
    |> TransactionSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
  def render("transactions.json", %{transactions: transactions}) do
    transactions
    |> TransactionSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
