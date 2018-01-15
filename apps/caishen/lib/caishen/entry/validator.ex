defmodule Caishen.Entry.Validator do
  @moduledoc """
  This module is used to validate that the total of debits minus the total of
  credits for an entry is equal to 0.
  """
  alias Caishen.Errors.InvalidAmountError

  @doc """
  Sum the incoming transactions and ensure debit - credit = 0. If not, raise
  an InvalidAmountError exception.
  """
  def validate_amount({debits, credits} = attrs) do
    sum = total(debits) - total(credits)

    case sum do
      0 ->
        attrs
      _ ->
        raise InvalidAmountError
    end
  end

  defp total(list) do
    Enum.reduce(list, 0, fn(attrs, acc) -> attrs["amount"] + acc end)
  end
end
