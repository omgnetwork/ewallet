defmodule EWallet.Web.V1.WalletOverlay do
  @behaviour EWallet.Web.V1.Overlay

  def preload_assocs,
    do: []

  def default_preload_assocs,
    do: []

  def search_fields, do: []
  def sort_fields, do: []
  def self_filter_fields, do: [:address, :name, :identifier, :inserted_at, :created_at]
  def filter_fields, do: []
end
