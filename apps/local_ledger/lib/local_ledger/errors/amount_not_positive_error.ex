defmodule LocalLedger.Errors.AmountNotPositiveError do
  defexception message: "One of provided amounts is less than or equal to zero."
end
