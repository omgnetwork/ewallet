defmodule LocalLedger.Errors.InvalidAmountError do
  defexception message: "Transaction could not be created.
                         Debit and Credit amounts were different."
end
