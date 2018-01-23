defmodule AdminAPI.V1.TransactionView do
  use AdminAPI, :view
  alias AdminAPI.V1.{ResponseSerializer, TransactionSerializer}

  def render("transaction.json", %{transaction: transaction}) do
    transaction
    |> TransactionSerializer.to_json()
    |> ResponseSerializer.to_json(success: true)
  end
  def render("transactions.json", %{transactions: transactions}) do
    transactions
    |> TransactionSerializer.to_json()
    |> ResponseSerializer.to_json(success: true)
  end
end
