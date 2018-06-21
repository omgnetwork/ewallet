defmodule LocalLedger.Transaction.Validator do
  @moduledoc """
  This module is used to validate that the total of debits minus the total of
  credits for a transaction is equal to 0.
  """
  alias LocalLedger.Errors.{InvalidAmountError, AmountNotPositiveError, SameAddressError}
  alias LocalLedgerDB.Entry

  def validate_different_addresses(entries) do
    identical_addresses =
      entries
      |> split_by_token()
      |> Enum.flat_map(&get_identical_addresses/1)

    case identical_addresses do
      [] ->
        entries

      addresses ->
        raise SameAddressError, message: SameAddressError.error_message(addresses)
    end
  end

  defp get_identical_addresses(entries) do
    {debits, credits} = split_debit_credit(entries)

    debit_addresses = extract_addresses(debits)
    credit_addresses = extract_addresses(credits)

    intersect(debit_addresses, credit_addresses)
  end

  @doc """
  Sum the incoming entries and ensure debit - credit = 0. If not, raise
  an InvalidAmountError exception.
  """
  def validate_zero_sum(entries) do
    entries_by_token = split_by_token(entries)

    case Enum.all?(entries_by_token, &is_zero_sum?/1) do
      true -> entries
      false -> raise InvalidAmountError
    end
  end

  defp split_by_token(entries) do
    entries
    |> Enum.group_by(fn entry -> entry["token"]["id"] end)
    |> Map.values()
  end

  defp is_zero_sum?(entries) do
    {debits, credits} = split_debit_credit(entries)
    total(debits) - total(credits) == 0
  end

  defp split_debit_credit(entries) do
    debit_type = Entry.debit_type()
    credit_type = Entry.credit_type()

    Enum.reduce(entries, {[], []}, fn entry, {debits, credits} ->
      case entry["type"] do
        ^debit_type ->
          {[entry | debits], credits}

        ^credit_type ->
          {debits, [entry | credits]}
      end
    end)
  end

  def validate_positive_amounts(entries) do
    case Enum.all?(entries, fn entry -> entry["amount"] > 0 end) do
      true -> entries
      false -> raise AmountNotPositiveError
    end
  end

  defp total(list) do
    Enum.reduce(list, 0, fn entry, acc -> entry["amount"] + acc end)
  end

  defp extract_addresses(list), do: Enum.map(list, fn e -> e["address"] end)
  defp intersect(a, b), do: a -- a -- b
end
