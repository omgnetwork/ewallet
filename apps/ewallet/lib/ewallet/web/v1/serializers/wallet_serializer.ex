# Copyright 2018 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWallet.Web.V1.WalletSerializer do
  @moduledoc """
  Serializes address data into V1 JSON response format.
  """
  alias Ecto.Association.NotLoaded
  alias EWallet.Web.{Paginator, BalanceLoader}

  alias EWallet.Web.V1.{
    AccountSerializer,
    BalanceSerializer,
    ListSerializer,
    PaginatorSerializer,
    UserSerializer
  }

  alias EWalletDB.{Wallet, Helpers.Preloader}
  alias Utils.Helpers.{Assoc, DateFormatter}

  def serialize(%Paginator{} = paginator) do
    PaginatorSerializer.serialize(paginator, &serialize/1)
  end

  def serialize(wallets) when is_list(wallets) do
    wallets
    |> Enum.map(&serialize/1)
    |> ListSerializer.serialize()
  end

  def serialize(%NotLoaded{}), do: nil
  def serialize(nil), do: nil

  def serialize(%Wallet{} = wallet) do
    wallet =
      case Map.get(wallet, :balances) do
        nil ->
          {:ok, wallet} = BalanceLoader.add_balances(wallet)
          wallet

        _ ->
          wallet
      end

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
      enabled: wallet.enabled,
      created_at: DateFormatter.to_iso8601(wallet.inserted_at),
      updated_at: DateFormatter.to_iso8601(wallet.updated_at)
    }
  end

  def serialize_without_balances(%Wallet{} = wallet) do
    wallet = Preloader.preload(wallet, [:user, :account])

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
      balances: nil,
      enabled: wallet.enabled,
      created_at: DateFormatter.to_iso8601(wallet.inserted_at),
      updated_at: DateFormatter.to_iso8601(wallet.updated_at)
    }
  end

  def serialize_without_balances(_), do: nil

  defp serialize_balances(balances) do
    Enum.map(balances, &BalanceSerializer.serialize/1)
  end
end
