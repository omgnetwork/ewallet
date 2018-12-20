defmodule EWallet.Web.V1.ConfigurationOverlay do
  @moduledoc """
  Overlay for the Setting schema.
  """
  @behaviour EWallet.Web.V1.Overlay

  def serializer, do: EWallet.Web.V1.ConfigSettingSerializer

  def preload_assocs,
    do: []

  def default_preload_assocs,
    do: []

  def search_fields,
    do: [
      :id,
      :key
    ]

  def sort_fields,
    do: [
      :id,
      :key,
      :type,
      :parent,
      :parent_value,
      :secret,
      :position
    ]

  def self_filter_fields,
    do: [
      :id,
      :key,
      :type,
      :description,
      :parent,
      :parent_value,
      :secret,
      :position
    ]

  def filter_fields,
    do: self_filter_fields()
end
