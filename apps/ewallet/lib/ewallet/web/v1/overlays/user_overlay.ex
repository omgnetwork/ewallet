defmodule EWallet.Web.V1.UserOverlay do
  @moduledoc """
  Overlay for the User schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.{
    InviteOverlay,
    WalletOverlay,
    AuthTokenOverlay,
    MembershipOverlay,
    RoleOverlay,
    AccountOverlay
  }

  def serializer, do: EWallet.Web.V1.UserSerializer

  def preload_assocs,
    do: []

  def default_preload_assocs,
    do: [:wallets]

  def sort_fields,
    do: [
      :id,
      :username,
      :email,
      :full_name,
      :calling_name,
      :provider_user_id,
      :inserted_at,
      :updated_at
    ]

  def search_fields,
    do: [
      :id,
      :username,
      :email,
      :full_name,
      :calling_name,
      :provider_user_id
    ]

  def self_filter_fields,
    do: [
      :id,
      :username,
      :email,
      :full_name,
      :calling_name,
      :provider_user_id,
      :inserted_at,
      :created_at
    ]

  def filter_fields,
    do: [
      id: nil,
      username: nil,
      email: nil,
      provider_user_id: nil,
      inserted_at: nil,
      created_at: nil,
      invite: InviteOverlay.default_preload_assocs(),
      wallets: WalletOverlay.default_preload_assocs(),
      auth_tokens: AuthTokenOverlay.default_preload_assocs(),
      memberships: MembershipOverlay.default_preload_assocs(),
      roles: RoleOverlay.default_preload_assocs(),
      accounts: AccountOverlay.default_preload_assocs()
    ]
end
