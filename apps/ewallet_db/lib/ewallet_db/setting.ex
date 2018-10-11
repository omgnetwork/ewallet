defmodule EWalletDB.Setting do
  @moduledoc """
  Schema overlay acting as an interface to the StoredSetting schema.
  This is needed because some transformation is applied to the
  attributes before saving them to the database. Indeed, value is stored
  in a map to allow any type to be saved, but is for simplicity, the
  users never need to know that - all they need to care is the "value"
  field.
  """
  alias EWalletDB.{Repo, StoredSetting, Setting}
  alias Ecto.Changeset

  @split_char ":|:"

  defstruct [
    :uuid,
    :id,
    :key,
    :value,
    :type,
    :options,
    :parent,
    :parent_value,
    :secret,
    :inserted_at,
    :updated_at
  ]

  @spec types() :: [String.t()]
  def types, do: StoredSetting.types()

  @doc """
  Retrieves a setting by its string name.
  """
  @spec get(String.t()) :: %Setting{}
  def get(key) when is_binary(key) do
    StoredSetting
    |> Repo.get_by(key: key)
    |> build()
  end

  @spec get(any()) :: nil
  def get(_), do: nil

  @doc """
  Creates a new setting with the passed attributes.
  """
  @spec insert(Map.t()) :: {:ok, %Setting{}} | {:error, %Changeset{}}
  def insert(attrs) do
    attrs = attrs |> cast_value() |> cast_options()

    %StoredSetting{}
    |> StoredSetting.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, stored_setting} ->
        {:ok, build(stored_setting)}
      {:error, changeset} ->
        {:error, %Changeset{
          action: changeset.action,
          changes: clean_changes(changeset.changes),
          errors: changeset.errors,
          data: %Setting{},
          valid?: changeset.valid?
        }}
    end
  end

  defp clean_changes(changes) do
    value = changes.data[:value]

    changes
    |> Map.delete(:data)
    |> Map.put(:value, value)
  end

  defp build(stored_setting) do
    %Setting{
      uuid: stored_setting.uuid,
      id: stored_setting.id,
      key: stored_setting.key,
      value: get_value(stored_setting),
      type: stored_setting.type,
      options: get_options(stored_setting),
      parent: stored_setting.parent,
      parent_value: stored_setting.parent_value,
      secret: stored_setting.secret,
      inserted_at: stored_setting.inserted_at,
      updated_at: stored_setting.updated_at
    }
  end

  defp get_value(%{secret: true, encrypted_data: data}) do
    Map.get(data, :value) || Map.get(data, "value")
  end

  defp get_value(%{secret: false, data: data}) do
    Map.get(data, :value) || Map.get(data, "value")
  end

  defp get_options(%{options: nil}), do: nil

  defp get_options(%{options: options}) do
    String.split(options, @split_char)
  end

  defp cast_value(%{secret: true, value: value} = attrs) do
    Map.put(attrs, :encrypted_data, %{value: value})
  end

  defp cast_value(%{value: value} = attrs) do
    Map.put(attrs, :data, %{value: value})
  end

  defp cast_value(attrs) do
    Map.put(attrs, :data, %{value: nil})
  end

  defp cast_options(%{options: options} = attrs) do
    Map.put(attrs, :options, Enum.join(options, @split_char))
  end

  defp cast_options(attrs), do: attrs
end
