defmodule KuberaDB.Helpers.Crypto do
  @moduledoc """
  A helper to perform crytographic operations
  """
  import Bitwise

  def compare(left, right) when is_nil(left) or is_nil(right), do: false
  def compare(left, right) when byte_size(left) != byte_size(right), do: false
  def compare(left, right) when is_binary(left) and is_binary(right) do
    left_list = String.to_charlist(left)
    right_list = String.to_charlist(right)

    compare(left_list, right_list)
  end
  def compare(left, right) when is_list(left) and is_list(right) do
    left
    |> Enum.zip(right)
    |> Enum.reduce(0, &do_bxor/2)
    |> Kernel.==(0)
  end

  defp do_bxor({left, right}, acc) do
    acc ||| bxor(left, right)
  end
end
