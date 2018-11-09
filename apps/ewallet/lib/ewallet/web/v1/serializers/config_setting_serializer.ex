defmodule EWallet.Web.V1.ConfigSettingSerializer do
  @moduledoc """
  Serializes setting(s) into V1 response format.
  """
  alias Ecto.Association.NotLoaded
  alias Ecto.Changeset
  alias EWallet.Web.V1.ErrorHandler
  alias EWallet.Web.{Date, Paginator}
  alias EWallet.Web.V1.PaginatorSerializer
  alias EWalletConfig.{Setting, StoredSetting}

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(settings) when is_list(settings) do
    %{
      object: "list",
      data: Enum.map(settings, &serialize/1)
    }
  end

  def serialize(%StoredSetting{} = setting) do
    setting
    |> Setting.build()
    |> serialize()
  end

  def serialize(%Setting{} = setting) do
    %{
      object: "configuration_setting",
      id: setting.id,
      key: setting.key,
      value: setting.value,
      type: setting.type,
      description: setting.description,
      options: setting.options,
      parent: setting.parent,
      parent_value: setting.parent_value,
      secret: setting.secret,
      position: setting.position,
      created_at: Date.to_iso8601(setting.inserted_at),
      updated_at: Date.to_iso8601(setting.updated_at)
    }
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  def serialize_with_errors(settings) when is_list(settings) do
    %{
      object: "map",
      data: Enum.reduce(settings, %{}, &serialize/2)
    }
  end

  def serialize(%StoredSetting{} = setting, data) do
    setting
    |> Setting.build()
    |> serialize(data)
  end

  def serialize({key, {:ok, setting}}, data) do
    Map.put(data, key, %{
      object: "configuration_setting",
      id: setting.id,
      key: setting.key,
      value: setting.value,
      type: setting.type,
      description: setting.description,
      options: setting.options,
      parent: setting.parent,
      parent_value: setting.parent_value,
      secret: setting.secret,
      position: setting.position,
      created_at: Date.to_iso8601(setting.inserted_at),
      updated_at: Date.to_iso8601(setting.updated_at)
    })
  end

  def serialize({key, {:error, %Changeset{} = changeset}}, data) do
    Map.put(
      data,
      key,
      ErrorHandler.build_error(:invalid_parameter, changeset, ErrorHandler.errors())
    )
  end

  def serialize({key, {:error, code}}, data) do
    Map.put(data, key, %{
      object: "configuration_setting_error",
      code: code,
      key: key
    })
  end

  def serialize(%NotLoaded{}, _), do: nil

  def serialize(settings, :id) when is_list(settings) do
    Enum.map(settings, fn setting -> setting.id end)
  end

  def serialize(%NotLoaded{}, _), do: nil
  def serialize(nil, _), do: nil
end
