defmodule EWallet.AmountFormatter do
  @moduledoc """
  A string formatter for amounts
  """
  def format(amount, subunit_to_unit) do
    subunit_to_unit
    |> to_decimals()
    |> float_to_binary(amount / subunit_to_unit)
    |> String.replace_trailing(".0", "")
  end

  defp float_to_binary(decimals, value) do
    :erlang.float_to_binary(value, [:compact, {:decimals, decimals}])
  end

  defp to_decimals(subunit_to_unit) do
    subunit_to_unit
    |> :math.log10()
    |> Kernel.trunc()
  end
end
