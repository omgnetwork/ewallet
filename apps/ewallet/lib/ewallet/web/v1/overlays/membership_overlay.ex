defmodule EWallet.Web.V1.MembershipOverlay do
  @moduledoc """
  Overlay for the Membership schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.{AccountOverlay, UserOverlay, RoleOverlay}

  def serializer, do: EWallet.Web.V1.MembershipSerializer

  def preload_assocs,
    do: [
      :role,
      :user,
      :account
    ]

  def default_preload_assocs,
    do: [
      :role,
      :user,
      account: [
        :parent,
        :categories
      ]
    ]

  def search_fields,
    do: [
      :id
    ]

  def sort_fields,
    do: [
      :id,
      :inserted_at,
      :updated_at
    ]

  def self_filter_fields,
    do: [
      :id,
      :inserted_at,
      :updated_at
    ]

  def filter_fields,
    do: [
      id: nil,
      inserted_at: nil,
      updated_at: nil,
      user: UserOverlay.self_filter_fields(),
      account: AccountOverlay.self_filter_fields(),
      role: RoleOverlay.self_filter_fields()
    ]
end
