defmodule LocalLedger.Errors.SameAddressError do
  defexception message: "Transaction could not be created. Some of the addresses are identical."

  def error_message(addresses) do
    addresses = Enum.join(addresses, ", ")
    "Found identical addresses in senders and receivers: #{addresses}."
  end
end
