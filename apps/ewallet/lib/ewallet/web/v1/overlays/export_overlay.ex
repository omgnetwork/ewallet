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
      :schema,
      :status,
      :completion,
      :url,
      :filename,
      :path,
      :failure_reason,
      :estimated_size,
      :total_count,
      :adapter,
      :inserted_at,
      :updated_at
    ]

  def filter_fields,
    do: [
      id: nil,
      schema: nil,
      status: nil,
      completion: nil,
      url: nil,
      filename: nil,
      path: nil,
      failure_reason: nil,
      estimated_size: nil,
      total_count: nil,
      adapter: nil,
      inserted_at: nil,
      updated_at: nil,
      user: UserOverlay.self_filter_fields(),
      key: KeyOverlay.self_filter_fields(),
    ]
end
