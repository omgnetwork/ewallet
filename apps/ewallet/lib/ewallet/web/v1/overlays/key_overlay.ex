defmodule EWallet.Web.V1.KeyOverlay do
  @behaviour EWallet.Web.V1.Overlay

  def preload_assocs, do: []

  def default_preload_assocs, do: []

  def search_fields, do: []

  def sort_fields, do: []
  def self_filter_fields, do: []

  def filter_fields, do: []
end
