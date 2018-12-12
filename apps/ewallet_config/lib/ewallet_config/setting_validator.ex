defmodule EWalletConfig.SettingValidator do
  @moduledoc """
  Contains custom validations for settings inserts and updates.
  """
  alias Ecto.Changeset


  def validate_positive_integer(%{changes: %{type: "integer"}} = changeset) do
    do_validate_positive_integer(changeset)
  end

  def validate_positive_integer(changeset, %{type: "integer"}) do
    do_validate_positive_integer(changeset)
  end

  def validate_positive_integer(changeset, _), do: changeset

  def do_validate_positive_integer(changeset) do
    value = get_value(changeset)
    case value > 0 do
      true  ->
        changeset
      false ->
        Changeset.add_error(
          changeset,
          :value,
          "must be a positive integer.",
          validation: :value_not_allowed
        )
    end
  end

  @spec validate_with_options(Changeset.t()) :: Changeset.t()
  def validate_with_options(%{changes: %{options: %{array: nil}}} = changeset) do
    changeset
  end

  def validate_with_options(%{changes: %{options: options}} = changeset) do
    options = Map.get(options, :array)

    changeset
    |> get_value()
    |> do_validate_with_options(options, changeset)
  end

  def validate_with_options(changeset) do
    changeset
  end

  @spec validate_with_options(Changeset.t(), Setting.t()) :: Changeset.t()
  def validate_with_options(changeset, %{options: nil}), do: changeset

  def validate_with_options(changeset, %{options: options}) do
    options = Map.get(options, "array")

    changeset
    |> get_value()
    |> do_validate_with_options(options, changeset)
  end

  defp do_validate_with_options(nil, _options, changeset) do
    changeset
  end

  defp do_validate_with_options(value, options, changeset) do
    case Enum.member?(options, value) do
      true ->
        changeset

      false ->
        Changeset.add_error(
          changeset,
          :value,
          "must be one of '#{Enum.join(options, "', '")}'",
          validation: :value_not_allowed
        )
    end
  end

  @spec validate_type(Changeset.t()) :: Changeset.t()
  def validate_type(%{errors: [type: {"is invalid", [validation: :inclusion]}]} = changeset) do
    changeset
  end

  def validate_type(%{changes: %{type: type}} = changeset) do
    changeset
    |> get_value()
    |> do_validate_type(%{type: type}, changeset)
  end

  def validate_type(changeset, setting) do
    changeset
    |> get_value(setting)
    |> do_validate_type(setting, changeset)
  end

  defp do_validate_type(nil, _, changeset) do
    changeset
  end

  defp do_validate_type(value, %{type: "string"}, changeset) when is_binary(value) do
    changeset
  end

  defp do_validate_type(value, %{type: "integer"}, changeset) when is_integer(value) do
    changeset
  end

  defp do_validate_type(value, %{type: "map"}, changeset) when is_map(value) do
    changeset
  end

  defp do_validate_type(value, %{type: "array"}, changeset) when is_list(value) do
    changeset
  end

  defp do_validate_type(value, %{type: "boolean"}, changeset) when is_boolean(value) do
    changeset
  end

  defp do_validate_type(_value, %{type: type}, changeset) do
    Changeset.add_error(
      changeset,
      :value,
      "must be of type '#{type}'",
      validation: :invalid_type_for_value
    )
  end

  defp get_value(%{changes: %{secret: true}} = changeset) do
    changeset
    |> Changeset.get_field(:encrypted_data)
    |> Map.get(:value)
  end

  defp get_value(changeset) do
    changeset
    |> Changeset.get_field(:data)
    |> Map.get(:value)
  end

  defp get_value(changeset, %{secret: true}) do
    changeset
    |> Changeset.get_field(:encrypted_data)
    |> Map.get(:value)
  end

  defp get_value(changeset, _setting) do
    changeset
    |> Changeset.get_field(:data)
    |> Map.get(:value)
  end
end
