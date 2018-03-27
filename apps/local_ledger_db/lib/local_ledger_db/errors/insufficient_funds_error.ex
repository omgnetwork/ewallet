defmodule LocalLedgerDB.Errors.InsufficientFundsError do
  defexception message: "This balance does not contain enough funds
                         for this transaction."

  def error_message(current_amount, %{
    amount: amount_to_debit,
    friendly_id: friendly_id,
    address: address
  }) do
    %{
      address: address,
      current_amount: current_amount,
      amount_to_debit: amount_to_debit,
      friendly_id: friendly_id
    }
  end
end
