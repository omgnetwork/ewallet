defmodule EWalletConfig.Setting do
  @moduledoc """
  Schema overlay acting as an interface to the StoredSetting schema.
  This is needed because some transformation is applied to the
  attributes before saving them to the database. Indeed, value is stored
  in a map to allow any type to be saved, but is for simplicity, the
  users never need to know that - all they need to care is the "value"
  field.

  Here are some explanations about some of the fields of the settings:

    - position

     Position is used to have a constant order for settings that we define.
    It cannot be updated and is only set at creation. We can add more settings
    in the seeds later and fix their positions.

    - parent and parent_value

    Those are used to link settings together in a very simple way. No logic is
    actually implemented for those, it's mostly intended to be used by clients
    (like the admin panel) to show settings in a logical way. So if someone
    selects gcs for file_storage, you can show all settings that have file_storage
    as a parent were parent_value=gcs.
  """
  require Ecto.Query
  alias EWalletConfig.{Repo, StoredSetting, Setting}
  alias Ecto.{Changeset, Query}

  defstruct [
    :uuid,
    :id,
    :key,
    :value,
    :type,
    :description,
    :options,
    :parent,
    :parent_value,
    :secret,
    :position,
    :inserted_at,
    :updated_at
  ]

  @spec get_setting_mappings() :: [Map.t()]
  def get_setting_mappings, do: Application.get_env(:ewallet_config, :settings_mappings)

  @spec get_default_settings() :: [Map.t()]
  def get_default_settings, do: Application.get_env(:ewallet_config, :default_settings)

  @spec types() :: [String.t()]
  def types, do: StoredSetting.types()

  @doc """
  Retrieves all settings.
  """
  @spec all() :: [%Setting{}]
  def all do
    StoredSetting
    |> Query.order_by(asc: :position)
    |> Repo.all()
    |> Enum.map(&build/1)
  end

  def query do
    StoredSetting
  end

  @doc """
  Retrieves a setting by its string name.
  """
  @spec get(String.t()) :: %Setting{}
  def get(key) when is_atom(key) do
    get(Atom.to_string(key))
  end

  def get(key) when is_binary(key) do
    case Repo.get_by(StoredSetting, key: key) do
      nil -> nil
      stored_setting -> build(stored_setting)
    end
  end

  def get(_), do: nil

  @doc """
  Retrieves a setting's value by its string name.
  """
  @spec get_value(String.t() | Atom.t()) :: any()
  def get_value(key, default \\ nil)

  def get_value(key, default) when is_atom(key) do
    key
    |> Atom.to_string()
    |> get_value(default)
  end

  def get_value(key, default) when is_binary(key) do
    case Repo.get_by(StoredSetting, key: key) do
      nil -> default
      stored_setting -> extract_value(stored_setting)
    end
  end

  def get_value(nil, _), do: nil

  @doc """
  Creates a new setting with the passed attributes.
  """
  @spec insert(Map.t()) :: {:ok, %Setting{}} | {:error, %Changeset{}}
  def insert(attrs) do
    attrs = cast_attrs(attrs)

    %StoredSetting{}
    |> StoredSetting.changeset(attrs)
    |> Repo.insert()
    |> return_from_change()
  end

  @doc """
  Inserts all the default settings.
  """
  @spec insert_all_defaults(Map.t()) :: [{:ok, %Setting{}}] | [{:error, %Changeset{}}]
  def insert_all_defaults(overrides \\ %{}) do
    Repo.transaction(fn ->
      get_default_settings()
      |> Enum.map(fn data -> insert_default(data, overrides) end)
      |> all_defaults_inserted?()
    end)
    |> return_tx_result()
  end

  defp insert_default({key, data}, overrides) do
    case overrides[key] do
      nil ->
        insert(data)

      override ->
        data
        |> Map.put(:value, override)
        |> insert()
    end
  end

  def all_defaults_inserted?(list) do
    Enum.all?(list, fn res ->
      case res do
        {:ok, _} -> true
        _ -> false
      end
    end)
  end

  defp return_tx_result({:ok, true}), do: :ok
  defp return_tx_result({:ok, false}), do: :error
  defp return_tx_result({:error, _}), do: {:error, :setting_insert_failed}

  @spec update(String.t(), Map.t()) ::
          {:ok, %Setting{}} | {:error, Atom.t()} | {:error, Changeset.t()}
  def update(nil, _), do: {:error, :setting_not_found}

  def update(key, attrs) when is_atom(key) and is_map(attrs) do
    key
    |> Atom.to_string()
    |> update(attrs)
  end

  def update(key, attrs) when is_binary(key) do
    case Repo.get_by(StoredSetting, %{key: key}) do
      nil ->
        {:error, :setting_not_found}

      setting ->
        attrs = cast_attrs(attrs)

        setting
        |> StoredSetting.update_changeset(attrs)
        |> Repo.update()
        |> return_from_change()
    end
  end

  @spec update_all(List.t()) :: [{:ok, %Setting{}} | {:error, Atom.t()} | {:error, Changeset.t()}]
  def update_all(attrs) when is_list(attrs) do
    Enum.map(attrs, fn data ->
      case data do
        {key, value} ->
          {key, update(key, %{value: value})}

        data ->
          key = data[:key] || data["key"]
          {key, update(key, data)}
      end
    end)
  end

  @spec update_all(Map.t()) :: [{:ok, %Setting{}} | {:error, Atom.t()} | {:error, Changeset.t()}]
  def update_all(attrs) do
    Enum.map(attrs, fn {key, value} ->
      {key, update(key, %{value: value})}
    end)
  end

  def lock_all do
    StoredSetting
    |> Query.lock("FOR UPDATE")
    |> Repo.all()
  end

  def lock(keys) do
    StoredSetting
    |> Query.lock("FOR UPDATE")
    |> Query.where([s], s.key in ^keys)
    |> Repo.all()
  end

  def build(stored_setting) do
    %Setting{
      uuid: stored_setting.uuid,
      id: stored_setting.id,
      key: stored_setting.key,
      value: extract_value(stored_setting),
      type: stored_setting.type,
      description: stored_setting.description,
      options: get_options(stored_setting),
      parent: stored_setting.parent,
      parent_value: stored_setting.parent_value,
      secret: stored_setting.secret,
      position: stored_setting.position,
      inserted_at: stored_setting.inserted_at,
      updated_at: stored_setting.updated_at
    }
  end

  defp return_from_change({:ok, stored_setting}) do
    {:ok, build(stored_setting)}
  end

  defp return_from_change({:error, changeset}) do
    {:error, changeset}
  end

  defp cast_attrs(attrs) do
    attrs
    |> cast_value()
    |> cast_options()
    |> add_position()
  end

  defp build_changeset(changeset) do
    %Changeset{
      action: changeset.action,
      changes: clean_changes(changeset.changes),
      errors: changeset.errors,
      data: %Setting{},
      valid?: changeset.valid?
    }
  end

  defp clean_changes(%{encrypted_data: data} = changes) do
    changes
    |> Map.delete(:encrypted_data)
    |> Map.put(:value, data[:value])
  end

  defp clean_changes(%{data: data} = changes) do
    changes
    |> Map.delete(:data)
    |> Map.put(:value, data[:value])
  end

  defp extract_value(%{secret: true, encrypted_data: nil}), do: nil

  defp extract_value(%{secret: true, encrypted_data: data}) do
    Map.get(data, :value) || Map.get(data, "value")
  end

  defp extract_value(%{secret: false, data: nil}), do: nil

  defp extract_value(%{secret: false, data: data}) do
    Map.get(data, :value) || Map.get(data, "value")
  end

  defp get_options(%{options: nil}), do: nil

  defp get_options(%{options: options}) do
    Map.get(options, :array) || Map.get(options, "array")
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

  defp cast_options(%{options: nil} = attrs), do: attrs

  defp cast_options(%{options: options} = attrs) do
    Map.put(attrs, :options, %{array: options})
  end

  defp cast_options(attrs), do: attrs

  defp add_position(%{position: position} = attrs)
       when not is_nil(position) and is_integer(position) do
    attrs
  end

  defp add_position(attrs) do
    case get_last_setting() do
      nil ->
        Map.put(attrs, :position, 0)

      latest_setting ->
        Map.put(attrs, :position, latest_setting.position + 1)
    end
  end

  defp get_last_setting do
    StoredSetting
    |> Query.order_by(desc: :position)
    |> Query.limit(1)
    |> Repo.one()
  end
end
