defmodule KuberaDB.Validator do
  @moduledoc """
  Custom validators that extend Ecto.Changeset's list of built-in validators.
  """
  alias Ecto.Changeset

  @doc """
  Validates that only one out of the provided fields can have value.
  """
  def validate_required_exclusive(changeset, attrs) do
    fields_found = Enum.count(attrs, fn(attr) ->
      value = Changeset.get_field(changeset, attr)
      value && value != ""
    end)

    case fields_found do
      1 ->
        changeset
      n when n > 1 ->
        Changeset.add_error(changeset, attrs, "only one must be present")
      _ ->
        Changeset.add_error(changeset, attrs, "can't all be blank")
    end
  end

  @doc """
  Validates that the value cannot be changed after it has been set.
  """
  def validate_immutable(changeset, key) do
    changed = Changeset.get_field(changeset, key)

    case Map.get(changeset.data, key) do
      nil -> changeset
      ^changed -> changeset
      _ -> Changeset.add_error(changeset, key, "can't be changed")
    end
  end
end
