defmodule EWallet.Web.V1.ModuleMapper do
  @moduledoc """
  This module provides a mapping configuration for each resource.
  """

  def config_for_module(module) do
    map = %{
      EWalletDB.User => %{
        overlay: EWallet.Web.V1.UserOverlay,
        serializer: EWallet.Web.V1.UserSerializer
      },
      EWalletDB.Key => %{
        overlay: EWallet.Web.V1.KeyOverlay,
        serializer: EWallet.Web.V1.KeySerializer
      },
      EWalletDB.Transaction => %{
        overlay: EWallet.Web.V1.TransactionOverlay,
        serializer: EWallet.Web.V1.TransactionSerializer
      },
      EWalletDB.Mint => %{
        overlay: EWallet.Web.V1.MintOverlay,
        serializer: EWallet.Web.V1.MintSerializer
      },
      EWalletDB.TransactionRequest => %{
        overlay: EWallet.Web.V1.TransactionRequestOverlay,
        serializer: EWallet.Web.V1.TransactionRequestSerializer
      },
      EWalletDB.TransactionConsumption => %{
        overlay: EWallet.Web.V1.TransactionConsumptionOverlay,
        serializer: EWallet.Web.V1.TransactionConsumptionSerializer
      },
      EWalletDB.Account => %{
        overlay: EWallet.Web.V1.AccountOverlay,
        serializer: EWallet.Web.V1.AccountSerializer
      },
      EWalletDB.Category => %{
        overlay: EWallet.Web.V1.CategoryOverlay,
        serializer: EWallet.Web.V1.CategorySerializer
      },
      EWalletDB.ExchangePair => %{
        overlay: EWallet.Web.V1.ExchangePairOverlay,
        serializer: EWallet.Web.V1.ExchangePairSerializer
      },
      EWalletDB.Wallet => %{
        overlay: EWallet.Web.V1.WalletOverlay,
        serializer: EWallet.Web.V1.WalletSerializer
      },
      EWalletDB.APIKey => %{
        overlay: EWallet.Web.V1.APIKeyOverlay,
        serializer: EWallet.Web.V1.APIKeySerializer
      },
      EWalletDB.Token => %{
        overlay: EWallet.Web.V1.TokenOverlay,
        serializer: EWallet.Web.V1.TokenSerializer
      },
      EWalletDB.Role => %{
        overlay: EWallet.Web.V1.RoleOverlay,
        serializer: EWallet.Web.V1.RoleSerializer
      },
      EWalletDB.Membership => %{
        overlay: EWallet.Web.V1.MembershipOverlay,
        serializer: EWallet.Web.V1.MembershipSerializer
      },
      EWalletDB.AuthToken => %{
        overlay: EWallet.Web.V1.AuthTokenOverlay,
        serializer: EWallet.Web.V1.UserAuthTokenSerializer
      },
      ActivityLogger.ActivityLog => %{
        overlay: EWallet.Web.V1.ActivityLogOverlay,
        serializer: EWallet.Web.V1.ActivityLogSerializer
      },
      EWalletConfig.StoredSetting => %{
        overlay: EWallet.Web.V1.ConfigurationOverlay,
        serializer: EWallet.Web.V1.ConfigurationSerializer
      }
    }

    map[module]
  end
end
