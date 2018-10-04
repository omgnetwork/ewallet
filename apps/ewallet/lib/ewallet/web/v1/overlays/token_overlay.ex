defmodule EWallet.Web.V1.TokenOverlay do
  @behaviour EWallet.Web.V1.Overlay

  def preload_assocs, do: []

  def default_preload_assocs, do: []

  def search_fields, do: []

  def sort_fields, do: []
  def self_filter_fields, do: [:id, :name, :symbol, :inserted_at, :created_at]
  def filter_fields, do: []
end
