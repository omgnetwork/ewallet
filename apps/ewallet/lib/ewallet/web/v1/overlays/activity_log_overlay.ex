defmodule EWallet.Web.V1.ActivityLogOverlay do
  @moduledoc """
  Overlay for the ActivityLog schema.
  """

  @behaviour EWallet.Web.V1.Overlay

  def preload_assocs, do: []

  def default_preload_assocs, do: []

  def search_fields,
    do: [
      :id,
      :action,
      :target_identifier,
      :target_type,
      :originator_identifier,
      :originator_type
    ]

  def sort_fields,
    do: [
      :id,
      :action,
      :target_identifier,
      :target_type,
      :originator_identifier,
      :originator_type,
      :inserted_at
    ]

  def self_filter_fields,
    do: [
      :id,
      :action,
      :target_identifier,
      :target_type,
      :originator_identifier,
      :originator_type,
      :inserted_at
    ]

  def filter_fields,
    do: [
      :id,
      :action,
      :target_identifier,
      :target_type,
      :originator_identifier,
      :originator_type,
      :inserted_at
    ]
end
