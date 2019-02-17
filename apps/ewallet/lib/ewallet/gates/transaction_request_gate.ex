# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule EWallet.TransactionRequestGate do
  @moduledoc """
  Business logic to manage transaction requests. This module is responsible
  for creating new requests, retrieving existing ones and handles the logic
  of picking the right wallet when inserting a new request.

  It is basically an interface to the EWalletDB.TransactionRequest schema.
  """
  alias EWallet.{
    ExchangeAccountFetcher,
    Helper,
    TokenFetcher,
    TransactionRequestFetcher,
    TransactionRequestPolicy,
    WalletFetcher
  }

  alias Utils.Helpers.Assoc
  alias EWalletDB.{Account, TransactionRequest, User, Wallet}

  @spec create(map()) :: {:ok, %TransactionRequest{}} | {:error, atom()}
  def create(
        %{
          "account_id" => account_id,
          "provider_user_id" => provider_user_id,
          "address" => address
        } = attrs
      ) do
    with %Account{} = account <- Account.get(account_id) || {:error, :account_id_not_found},
         %User{} = user <-
           User.get_by_provider_user_id(provider_user_id) || {:error, :provider_user_id_not_found},
         {:ok, wallet} <- WalletFetcher.get(user, address),
         wallet <- Map.put(wallet, :account_uuid, account.uuid),
         {:ok, transaction_request} <- create(wallet, attrs) do
      TransactionRequestFetcher.get(transaction_request.id)
    else
      error -> error
    end
  end

  def create(
        %{
          "account_id" => account_id,
          "user_id" => user_id,
          "address" => address
        } = attrs
      ) do
    with %Account{} = account <- Account.get(account_id) || {:error, :account_id_not_found},
         %User{} = user <- User.get(user_id) || {:error, :provider_user_id_not_found},
         {:ok, wallet} <- WalletFetcher.get(user, address),
         wallet <- Map.put(wallet, :account_uuid, account.uuid),
         {:ok, transaction_request} <- create(wallet, attrs) do
      TransactionRequestFetcher.get(transaction_request.id)
    else
      error -> error
    end
  end

  def create(
        %{
          "account_id" => account_id,
          "address" => address
        } = attrs
      ) do
    with %Account{} = account <- Account.get(account_id) || {:error, :account_id_not_found},
         {:ok, wallet} <- WalletFetcher.get(account, address),
         {:ok, transaction_request} <- create(wallet, attrs) do
      TransactionRequestFetcher.get(transaction_request.id)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def create(%{"account_id" => _} = attrs) do
    attrs
    |> Map.put("address", nil)
    |> create()
  end

  def create(
        %{
          "provider_user_id" => provider_user_id,
          "address" => address
        } = attrs
      ) do
    with %User{} = user <-
           User.get_by_provider_user_id(provider_user_id) || {:error, :provider_user_id_not_found},
         {:ok, wallet} <- WalletFetcher.get(user, address),
         {:ok, transaction_request} <- create(wallet, attrs) do
      TransactionRequestFetcher.get(transaction_request.id)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def create(
        %{
          "user_id" => user_id,
          "address" => address
        } = attrs
      ) do
    with %User{} = user <- User.get(user_id) || {:error, :provider_user_id_not_found},
         {:ok, wallet} <- WalletFetcher.get(user, address),
         {:ok, transaction_request} <- create(wallet, attrs) do
      TransactionRequestFetcher.get(transaction_request.id)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def create(%{"provider_user_id" => _} = attrs) do
    attrs
    |> Map.put("address", nil)
    |> create()
  end

  def create(%{"user_id" => _} = attrs) do
    attrs
    |> Map.put("address", nil)
    |> create()
  end

  def create(
        %{
          "address" => address
        } = attrs
      ) do
    with {:ok, wallet} <- WalletFetcher.get(nil, address),
         {:ok, transaction_request} <- create(wallet, attrs) do
      TransactionRequestFetcher.get(transaction_request.id)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def create(_), do: {:error, :invalid_parameter}

  @spec create(%User{} | %Wallet{}, map()) :: {:ok, %TransactionRequest{}} | {:error, atom()}
  def create(
        %User{} = user,
        attrs
      ) do
    with {:ok, wallet} <- WalletFetcher.get(user, attrs["address"]),
         attrs <- Map.put(attrs, "creator", %{end_user: user}) do
      create(wallet, attrs)
    else
      error -> error
    end
  end

  def create(
        %Wallet{} = wallet,
        %{
          "type" => _,
          "token_id" => token_id,
          "creator" => creator
        } = attrs
      ) do
    with true <- wallet.enabled || {:error, :wallet_is_disabled},
         :ok <- Bodyguard.permit(TransactionRequestPolicy, :create, creator, wallet),
         {:ok, token} <- TokenFetcher.fetch(%{"token_id" => token_id}),
         {:ok, amount} <- get_integer_or_string_amount(attrs["amount"]),
         {:ok, exchange_wallet} <- ExchangeAccountFetcher.fetch(attrs),
         {:ok, transaction_request} <- insert(token, wallet, exchange_wallet, amount, attrs) do
      TransactionRequestFetcher.get(transaction_request.id)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def create(_, _attrs), do: {:error, :invalid_parameter}

  @spec expire_if_past_expiration_date(%TransactionRequest{}, map()) ::
          {:ok, %TransactionRequest{}}
          | {:error, atom()}
          | {:error, map()}
  def expire_if_past_expiration_date(request, originator) do
    res = TransactionRequest.expire_if_past_expiration_date(request, originator)

    case res do
      {:ok, %TransactionRequest{status: "expired"} = request} ->
        {:error, String.to_existing_atom(request.expiration_reason)}

      {:ok, request} ->
        {:ok, request}

      {:error, error} ->
        {:error, error}
    end
  end

  defp insert(token, wallet, exchange_wallet, amount, attrs) do
    require_confirmation = default_to_if_nil(attrs["require_confirmation"], false)
    allow_amount_override = default_to_if_nil(attrs["allow_amount_override"], true)

    TransactionRequest.insert(%{
      type: attrs["type"],
      correlation_id: attrs["correlation_id"],
      amount: amount,
      user_uuid: wallet.user_uuid,
      account_uuid: wallet.account_uuid,
      token_uuid: token.uuid,
      wallet_address: wallet.address,
      allow_amount_override: allow_amount_override,
      require_confirmation: require_confirmation,
      consumption_lifetime: attrs["consumption_lifetime"],
      metadata: attrs["metadata"] || %{},
      encrypted_metadata: attrs["encrypted_metadata"] || %{},
      expiration_date: attrs["expiration_date"],
      max_consumptions: attrs["max_consumptions"],
      max_consumptions_per_user: attrs["max_consumptions_per_user"],
      exchange_account_uuid: Assoc.get_if_exists(exchange_wallet, [:account_uuid]),
      exchange_wallet_address: Assoc.get_if_exists(exchange_wallet, [:address]),
      originator: attrs["originator"]
    })
  end

  defp default_to_if_nil(field, default) when is_nil(field), do: default
  defp default_to_if_nil(field, _default), do: field

  defp get_integer_or_string_amount(amount) when is_binary(amount) do
    Helper.string_to_integer(amount)
  end

  defp get_integer_or_string_amount(amount), do: {:ok, amount}
end
