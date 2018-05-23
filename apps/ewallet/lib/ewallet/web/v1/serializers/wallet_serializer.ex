defmodule EWallet.Web.V1.WalletSerializer do
  @moduledoc """
  Serializes address data into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Date, Paginator}

  alias EWallet.Web.V1.{
    AccountSerializer,
    UserSerializer,
    BalanceSerializer,
    PaginatorSerializer
  }

  alias EWallet.BalanceFetcher
  alias EWalletDB.Wallet

  alias EWalletDB.Helpers.{Assoc, Preloader}

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(wallets) when is_list(wallets) do
    Enum.map(wallets, &serialize/1)
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  def serialize(%Wallet{} = wallet) do
    wallet = Preloader.preload(wallet, [:user, :account])
    {:ok, wallet} = BalanceFetcher.all(%{"wallet" => wallet})

    %{
      object: "wallet",
      socket_topic: "wallet:#{wallet.address}",
      address: wallet.address,
      name: wallet.name,
      identifier: wallet.identifier,
      metadata: wallet.metadata,
      encrypted_metadata: wallet.encrypted_metadata,
      user_id: Assoc.get(wallet, [:user, :id]),
      user: UserSerializer.serialize(wallet.user),
      account_id: Assoc.get(wallet, [:account, :id]),
      account: AccountSerializer.serialize(wallet.account),
      balances: serialize_balances(wallet.balances),
      created_at: Date.to_iso8601(wallet.inserted_at),
      updated_at: Date.to_iso8601(wallet.updated_at)
    }
  end

  defp serialize_balances(balances) do
    Enum.map(balances, &BalanceSerializer.serialize/1)
  end
end
