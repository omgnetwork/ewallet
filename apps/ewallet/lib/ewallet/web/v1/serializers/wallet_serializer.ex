defmodule EWallet.Web.V1.WalletSerializer do
  @moduledoc """
  Serializes address data into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded

  alias EWallet.Web.V1.{
    AccountSerializer,
    UserSerializer,
    BalanceSerializer
  }

  alias EWalletDB.Helpers.{Assoc, Preloader}

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  def serialize(wallet) do
    wallet = Preloader.preload(wallet, [:account, :user])

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
      balances: serialize_balances(wallet.balances)
    }
  end

  defp serialize_balances(balances) do
    Enum.map(balances, &BalanceSerializer.serialize/1)
  end
end
