defmodule EWallet.Web.V1.RoleOverlay do
  @moduledoc """
  Overlay for the Role schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.{UserOverlay}

  def preload_assocs,
    do: [
      :users
    ]

  def default_preload_assocs,
    do: []

  def search_fields,
    do: [
      :id,
      :name,
      :display_name
    ]

  def sort_fields,
    do: [
      :id,
      :name,
      :display_name,
      :priority,
      :inserted_at,
      :updated_at
    ]

  def self_filter_fields,
    do: [
      :id,
      :name,
      :display_name,
      :priority,
      :inserted_at,
      :updated_at
    ]

  def filter_fields,
    do: [
      id: nil,
      name: nil,
      display_name: nil,
      priority: nil,
      inserted_at: nil,
      updated_at: nil,
      users: UserOverlay.self_filter_fields()
    ]
end
