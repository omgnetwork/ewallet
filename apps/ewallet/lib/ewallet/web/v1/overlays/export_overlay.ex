defmodule ExportOverlay do
  @moduledoc """
  Overlay for the Export schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.{
    UserOverlay,
    KeyOverlay
  }

  def preload_assocs,
    do: [
      :user, :key
    ]

  def default_preload_assocs,
    do: []

  def search_fields,
    do: [
      :id,
      :filename
    ]

  def sort_fields,
    do: [
      :id,
      :filename,
      :inserted_at,
      :updated_at
    ]

  def self_filter_fields,
    do: [
      :id,
      :filename,
      :inserted_at,
      :updated_at
    ]

  def filter_fields,
    do: [
      id: nil,
      filename: nil,
      inserted_at: nil,
      updated_at: nil,
      user: UserOverlay.self_filter_fields(),
      key: KeyOverlay.self_filter_fields(),
    ]
end
