# Copyright 2018-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWalletConfig.Validator do
  @moduledoc """
  Custom validators that extend Ecto.Changeset's list of built-in validators.
  """
  alias Ecto.Changeset

  @doc """
  Validates that only one out of the provided fields can have value.
  """
  def validate_required_exclusive(changeset, attrs) when is_map(attrs) or is_list(attrs) do
    case count_fields_present(changeset, attrs) do
      1 ->
        changeset

      n when n > 1 ->
        Changeset.add_error(
          changeset,
          attrs,
          "only one must be present",
          validation: :only_one_required
        )

      _ ->
        Changeset.add_error(
          changeset,
          attrs,
          "can't all be blank",
          validation: :required_exclusive
        )
    end
  end

  @doc """
  Validates that either all or none the given fields are present.
  """
  def validate_required_all_or_none(changeset, attrs) do
    num_attrs = Enum.count(attrs)
    missing_attrs = Enum.filter(attrs, fn attr -> !field_present?(changeset, attr) end)

    case Enum.count(missing_attrs) do
      0 ->
        changeset

      ^num_attrs ->
        changeset

      _ ->
        Changeset.add_error(
          changeset,
          attrs,
          "either all or none of them must be present",
          validation: "all_or_none"
        )
    end
  end

  @doc """
  Validates that only one out of the provided fields can have value but
  both can be nil.
  """
  def validate_exclusive(changeset, attrs) when is_map(attrs) or is_list(attrs) do
    case count_fields_present(changeset, attrs) do
      n when n > 1 ->
        Changeset.add_error(
          changeset,
          attrs,
          "only one must be present",
          validation: :only_one_required
        )

      _ ->
        changeset
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

  def count_fields_present(changeset, attrs) do
    Enum.count(attrs, fn attr -> field_present?(changeset, attr) end)
  end

  def field_present?(changeset, attr) when is_atom(attr) do
    value = Changeset.get_field(changeset, attr)
    value && value != ""
  end

  def field_present?(changeset, {attr, nil}), do: field_present?(changeset, attr)

  def field_present?(changeset, {attr, attr_value}) do
    value = Changeset.get_field(changeset, attr)
    value && value != "" && value == attr_value
  end
end
