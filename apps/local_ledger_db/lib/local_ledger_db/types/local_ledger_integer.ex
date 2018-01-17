defmodule LocalLedger.Types.Integer do
  @moduledoc false
  @behaviour Ecto.Type
  def type, do: :integer

  def cast(value) do
    {:ok, value}
  end

  def load(value) do
    {:ok, Decimal.to_integer(value)}
  end

  def dump(value) do
    {:ok, value}
  end
end
