defmodule EWalletConfig.Types.VirtualStruct do
  @moduledoc """
  Useless type used for the virtual struct "originator".
  """
  @behaviour Ecto.Type
  def type, do: :virtual_struct

  def cast(value) do
    {:ok, value}
  end

  def load(value) do
    {:ok, value}
  end

  def load!(nil), do: 0

  def load!(value), do: value

  def dump(value) do
    {:ok, value}
  end
end
