defmodule LocalLedgerDB.Errors.InsufficientFundsError do
  defexception message: "This wallet does not contain enough funds
                         for this transaction."

  def error_message(current_amount, %{
        amount: amount_to_debit,
        minted_token_id: minted_token_id,
        address: address
      }) do
    %{
      address: address,
      current_amount: current_amount,
      amount_to_debit: amount_to_debit,
      minted_token_id: minted_token_id
    }
  end
end
