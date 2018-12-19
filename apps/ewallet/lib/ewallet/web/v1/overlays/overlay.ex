defmodule EWallet.Web.V1.Overlay do
  @moduledoc """
  Behavior definition for overlays.
  """

  # The serializer corresponding
  @callback serializer() :: module() | nil

  # The fields that can be preloaded.
  @callback preload_assocs() :: [Atom.t()]

  # The fields that should always be preloaded.
  # Note that these values *must be in the schema associations*.
  @callback default_preload_assocs() :: [Atom.t()]

  # The fields that are allowed to be searched.
  # Note that these values here *must be the DB column names*
  # Because requests cannot customize which fields to search (yet!),
  @callback search_fields() :: [Atom.t()]

  # The fields that are allowed to be sorted.
  # Note that the values here *must be the DB column names*.
  @callback sort_fields() :: [Atom.t()]

  # The fields that are allowed to be filtered.
  @callback self_filter_fields() :: [Atom.t()]
  @callback filter_fields() :: [Atom.t()]

  def overlay_for_module(module) do
    map = %{
      EWalletDB.User => EWallet.Web.V1.UserOverlay,
      EWalletDB.Key => EWallet.Web.V1.KeyOverlay,
      EWalletDB.Transaction => EWallet.Web.V1.TransactionOverlay,
      EWalletDB.Mint => EWallet.Web.V1.MintOverlay,
      EWalletDB.TransactionRequest => EWallet.Web.V1.TransactionRequestOverlay,
      EWalletDB.TransactionConsumption => EWallet.Web.V1.TransactionConsumptionOverlay,
      EWalletDB.Account => EWallet.Web.V1.AccountOverlay,
      EWalletDB.Category => EWallet.Web.V1.CategoryOverlay,
      EWalletDB.ExchangePair => EWallet.Web.V1.ExchangePairOverlay,
      EWalletDB.Wallet => EWallet.Web.V1.WalletOverlay,
      EWalletDB.APIKey => EWallet.Web.V1.APIKeyOverlay,
      EWalletDB.Token => EWallet.Web.V1.TokenOverlay,
      EWalletDB.Role => EWallet.Web.V1.RoleOverlay,
      EWalletDB.Membership => EWallet.Web.V1.MembershipOverlay,
      EWalletDB.AuthToken => EWallet.Web.V1.AuthTokenOverlay,
      EWalletConfig.StoredSetting => EWallet.Web.V1.SettingOverlay
    }

    map[module]
  end
end
