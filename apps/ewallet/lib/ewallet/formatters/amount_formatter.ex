defmodule EWallet.AmountFormatter do
  @moduledoc """
  A string formatter for amounts
  """
  def format(amount, subunit_to_unit) do
    float_amount = amount / subunit_to_unit

    float_amount
    |> float_to_binary(to_decimals(subunit_to_unit))
    |> String.replace_trailing(".0", "")
  end

  defp float_to_binary(value, decimals) do
    :erlang.float_to_binary(value, [:compact, {:decimals, decimals}])
  end

  defp to_decimals(subunit_to_unit) do
    Kernel.trunc(:math.log10(subunit_to_unit))
  end
end
