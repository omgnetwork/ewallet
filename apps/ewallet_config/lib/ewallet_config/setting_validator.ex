# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWalletConfig.SettingValidator do
  @moduledoc """
  Contains custom validations for settings inserts and updates.
  """
  alias Ecto.Changeset

  @doc """
  Validate that the value is allowed by the setting's options.
  """
  @spec validate_setting_with_options(Changeset.t()) :: Changeset.t()
  def validate_setting_with_options(changeset) do
    value = get_value(changeset)
    options = get_options(changeset)

    if valid_with_options?(value, options) do
      changeset
    else
      Changeset.add_error(
        changeset,
        :value,
        "must be one of '#{Enum.join(options, "', '")}'",
        validation: :value_not_allowed
      )
    end
  end

  # Skip when the value is nil
  defp valid_with_options?(nil, _), do: true

  # Skip when the options is nil
  defp valid_with_options?(_, nil), do: true

  # Evaluate the rest
  defp valid_with_options?(value, options), do: Enum.member?(options, value)

  @doc """
  Validate that the value is compatible with the setting's type.
  """
  @spec validate_setting_type(Changeset.t()) :: Changeset.t()

  # Skip if the setting type is already invalid
  def validate_setting_type(
        %{errors: [type: {"is invalid", [validation: :inclusion]}]} = changeset
      ) do
    changeset
  end

  def validate_setting_type(changeset) do
    value = get_value(changeset)
    type = get_type(changeset)

    if valid_setting_type?(value, type) do
      changeset
    else
      Changeset.add_error(
        changeset,
        :value,
        "must be of type '#{type}'",
        validation: :invalid_type_for_value
      )
    end
  end

  #
  # Setting's type-value validator
  #

  defp valid_setting_type?(nil, _), do: true

  defp valid_setting_type?(value, "string") when is_binary(value), do: true

  defp valid_setting_type?(value, "integer") when is_integer(value), do: true

  defp valid_setting_type?(value, "unsigned_integer") when is_integer(value) and value >= 0 do
    true
  end

  defp valid_setting_type?(value, "map") when is_map(value), do: true

  defp valid_setting_type?(value, "array") when is_list(value), do: true

  defp valid_setting_type?(value, "boolean") when is_boolean(value), do: true

  defp valid_setting_type?(_, _), do: false

  #
  # Changeset getters
  #
  defp get_options(changeset) do
    case Changeset.get_field(changeset, :options) do
      nil -> nil
      options -> Map.get(options, :array) || Map.get(options, "array")
    end
  end

  defp get_type(changeset) do
    Changeset.get_field(changeset, :type)
  end

  defp get_value(changeset) do
    case Changeset.get_field(changeset, :secret) do
      true ->
        changeset
        |> Changeset.get_field(:encrypted_data)
        |> Map.get(:value)

      false ->
        changeset
        |> Changeset.get_field(:data)
        |> Map.get(:value)
    end
  end
end
