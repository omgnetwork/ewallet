defmodule Utils.Types.Integer do
  @moduledoc """
  Custom Ecto type that converts DB's decimal value into integer.

  Ecto supports `:decimal` type out of the box (via `decimal` package). However,
  since this `:decimal` type requires its own functions to operate, e.g. `Decimal.add/2`,
  and we only work with whole numbers, we can safely convert to Elixir's primitive integer for easier operations.
  """
  @behaviour Ecto.Type
  def type, do: :integer

  def cast(value) do
    {:ok, value}
  end

  def load(value) do
    {:ok, Decimal.to_integer(value)}
  end

  def load!(nil), do: 0

  def load!(value), do: Decimal.to_integer(value)

  def dump(value) do
    {:ok, value}
  end
end
