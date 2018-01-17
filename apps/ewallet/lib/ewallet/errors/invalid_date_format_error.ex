defmodule EWallet.Errors.InvalidDateFormatError do
  defexception message: "Invalid date format error, supports only NaiveDateTime and DateTime"
end
