defmodule EWallet.Web.V1.UserOverlay do
  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.{}

  def preload_assocs,
    do: []

  def default_preload_assocs,
    do: []

  def sort_fields,
    do: []

  def search_fields,
    do: []

  def self_filter_fields,
    do: [
      :id,
      :username,
      :email,
      :provider_user_id,
      :inserted_at,
      :created_at
    ]

  def filter_fields,
    do: []
end
