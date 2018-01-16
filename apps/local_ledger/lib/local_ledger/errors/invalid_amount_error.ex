defmodule LocalLedger.Errors.InvalidAmountError do
  defexception message: "Entry could not be created.
                         Debit and Credit amounts were different."
end
