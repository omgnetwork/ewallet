defmodule EWallet.AmountFormatter do
  @moduledoc """
  A string formatter for amounts
  """
  def format(amount, subunit_to_unit) do
    Decimal.set_context(%Decimal.Context{Decimal.get_context() | precision: 38})

    amount
    |> Decimal.div(subunit_to_unit)
    |> Decimal.to_string(:normal)
  end
end
