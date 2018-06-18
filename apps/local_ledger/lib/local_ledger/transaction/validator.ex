defmodule LocalLedger.Transaction.Validator do
  @moduledoc """
  This module is used to validate that the total of debits minus the total of
  credits for a transaction is equal to 0.
  """
  alias LocalLedger.Errors.{InvalidAmountError, AmountIsZeroError, SameAddressError}

  def validate_different_addresses({debits, credits} = attrs) do
    debit_addresses = extract_addresses(debits)
    credit_addresses = extract_addresses(credits)
    identical_addresses = intersect(debit_addresses, credit_addresses)

    case length(identical_addresses) do
      0 -> attrs
      _ -> raise SameAddressError, message: SameAddressError.error_message(identical_addresses)
    end
  end

  @doc """
  Sum the incoming entries and ensure debit - credit = 0. If not, raise
  an InvalidAmountError exception.
  """
  def validate_zero_sum({debits, credits} = attrs) do
    sum = total(debits) - total(credits)

    case sum do
      0 -> attrs
      _ -> raise InvalidAmountError
    end
  end

  def validate_positive_amounts({debits, credits} = attrs) do
    case Enum.any?(debits ++ credits, fn attrs -> attrs["amount"] == 0 end) do
      true -> raise AmountIsZeroError
      false -> attrs
    end
  end

  defp total(list) do
    Enum.reduce(list, 0, fn attrs, acc -> attrs["amount"] + acc end)
  end

  defp extract_addresses(list), do: Enum.map(list, fn e -> e["address"] end)
  defp intersect(a, b), do: a -- a -- b
end
