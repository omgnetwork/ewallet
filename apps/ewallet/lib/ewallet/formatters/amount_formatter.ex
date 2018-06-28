defmodule EWallet.AmountFormatter do
  @moduledoc """
  A string formatter for amounts
  """
  def format(amount, subunit_to_unit) do
    amount
    |> Decimal.div(subunit_to_unit)
    |> Decimal.to_string(:normal)
  end
end
