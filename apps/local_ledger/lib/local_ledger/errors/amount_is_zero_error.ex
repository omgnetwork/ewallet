defmodule LocalLedger.Errors.AmountIsZeroError do
  defexception message: "One of provided amounts is equal to zero."
end
