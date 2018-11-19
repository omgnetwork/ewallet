defmodule EWallet.Web.V1.InviteOverlay do
  @moduledoc """
  Overlay for the Invite schema.
  """

  @behaviour EWallet.Web.V1.Overlay
  alias EWallet.Web.V1.{
    UserOverlay
  }

  def preload_assocs,
    do: [:user]

  def default_preload_assocs,
    do: [:user]

  def sort_fields,
    do: [
      :id,
      :token,
      :verified_at,
      :inserted_at,
      :updated_at
    ]

  def search_fields,
    do: [:id, :token]

  def self_filter_fields,
    do: [
      :id,
      :token,
      :success_url,
      :verified_at,
      :inserted_at,
      :updated_at
    ]

  def filter_fields,
    do: [
      id: nil,
      token: nil,
      success_url: nil,
      verified_at: nil,
      inserted_at: nil,
      updated_at: nil,
      user: UserOverlay.default_preload_assocs()
    ]

end
