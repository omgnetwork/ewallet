defmodule CaishenDB.Errors.InsufficientFundsError do
  defexception message: "This balance does not contain enough funds
                         for this transaction."

  def error_message(current_amount, %{
    amount: amount_to_debit,
    friendly_id: friendly_id,
    address: address
  }) do
    "The specified balance (#{address}) does not contain enough funds. " <>
    "Available: #{current_amount} #{friendly_id} - Attempted debit: " <>
    "#{amount_to_debit} #{friendly_id}"
  end
end
