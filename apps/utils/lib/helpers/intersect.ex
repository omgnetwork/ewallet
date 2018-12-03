defmodule Utils.Intersecter do
  @moduledoc """
  Module to intersect lists.
  """

  def intersect(a, b), do: a -- a -- b
end
