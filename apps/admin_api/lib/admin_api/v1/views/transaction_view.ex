defmodule AdminAPI.V1.TransactionView do
  use AdminAPI, :view
  alias EWallet.Web.V1.{ResponseSerializer, ExportSerializer, TransactionSerializer}

  def render("export.json", %{export: export}) do
    export
    |> ExportSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

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
