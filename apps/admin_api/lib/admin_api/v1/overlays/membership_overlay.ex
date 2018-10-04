defmodule AdminAPI.V1.MembershipOverlay do
  @behaviour EWallet.Web.V1.Overlay

  def preload_assocs, do: [
    :role,
    :user,
    :account
  ]

  def default_preload_assocs, do: [
    :role,
    :user,
    account: [
      :parent,
      :categories
    ]
  ]

  def search_fields, do: []
  def sort_fields, do: []
end
