defmodule EWallet.Helper do
  @moduledoc """
  The module for generic helpers.
  """

  @doc """
  Converts a list of strings to a list of existing atoms.

  If the string does not match an existing atom, it is skipped from the resulting list.
  """
  def to_existing_atoms(strings) do
    strings
    |> Enum.reduce([], &to_existing_atoms/2)
    |> Enum.reverse()
  end

  def to_existing_atoms(string, atom_list) do
    atom = String.to_existing_atom(string)
    [atom | atom_list]
  rescue
    ArgumentError -> atom_list
  end

  @doc """
  Checks if all `elements` exist within the `enumerable`.

  Membership is tested with the match (`===`) operator.
  """
  def members?(enumerable, elements) do
    Enum.all?(elements, fn element ->
      Enum.member?(enumerable, element)
    end)
  end

  def intersect(a, b), do: a -- a -- b
end
