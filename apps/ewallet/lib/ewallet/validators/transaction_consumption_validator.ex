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

defmodule EWallet.TransactionConsumptionValidator do
  @moduledoc """
  Handles all validations for a transaction request, including amount and
  expiration.
  """
  alias EWallet.{Helper, TokenFetcher, TransactionRequestPolicy, TransactionConsumptionPolicy}
  alias EWallet.Web.V1.Event
  alias EWalletDB.{ExchangePair, Repo, Token, TransactionConsumption, TransactionRequest, Wallet}
  alias ActivityLogger.System

  @spec validate_before_consumption(
          %TransactionRequest{},
          %Wallet{},
          %Wallet{},
          nil | keyword() | map()
        ) ::
          {:ok, %TransactionRequest{}, %Token{}, integer() | nil}
          | {:error, atom()}
  def validate_before_consumption(
        request,
        wallet,
        %{"creator" => creator} = attrs,
        wallet_exchange \\ nil
      ) do
    with amount <- attrs["amount"],
         token_id <- attrs["token_id"],
         {:ok, _} <-
           TransactionConsumptionPolicy.authorize(:create, creator, %TransactionConsumption{
             user_uuid: wallet.user_uuid,
             account_uuid: wallet.account_uuid
           }),
         true <- wallet.enabled || {:error, :wallet_is_disabled},
         :ok <- validate_only_one_exchange_address_in_pair(request, wallet_exchange),
         {:ok, request} <- TransactionRequest.expire_if_past_expiration_date(request, %System{}),
         true <- TransactionRequest.valid?(request) || request.expiration_reason,
         {:ok, amount} <- validate_amount(request, amount),
         {:ok, _wallet} <- validate_max_consumptions_per_user(request, wallet),
         {:ok, nil} <- validate_max_consumptions_per_interval(request),
         {:ok, _wallet} <- validate_max_consumptions_per_interval_per_user(request, wallet),
         {:ok, token} <- get_and_validate_token(request, token_id) do
      {:ok, request, token, amount}
    else
      error when is_binary(error) ->
        {:error, String.to_existing_atom(error)}

      error when is_atom(error) ->
        {:error, error}

      {:error, %{}} ->
        {:error, :unauthorized}

      error ->
        error
    end
  end

  @spec validate_before_confirmation(
          %TransactionConsumption{},
          %EWalletDB.Account{} | %EWalletDB.User{}
        ) ::
          {:ok, %TransactionConsumption{}}
          | {:error, atom()}
          | no_return()
  def validate_before_confirmation(consumption, creator) do
    with {request, wallet} <- {consumption.transaction_request, consumption.wallet},
         request <- Repo.preload(request, [:wallet]),
         {:ok, _} <- TransactionRequestPolicy.authorize(:confirm, creator, request),
         {:ok, request} <- TransactionRequest.expire_if_past_expiration_date(request, %System{}),
         {:ok, _wallet} <- validate_max_consumptions_per_user(request, wallet),
         {:ok, nil} <- validate_max_consumptions_per_interval(request),
         {:ok, _wallet} <- validate_max_consumptions_per_interval_per_user(request, wallet),
         true <- TransactionRequest.valid?(request) || request.expiration_reason,
         {:ok, consumption} =
           TransactionConsumption.expire_if_past_expiration_date(consumption, %System{}) do
      case TransactionConsumption.expired?(consumption) do
        false ->
          {:ok, consumption}

        true ->
          Event.dispatch(:transaction_consumption_finalized, %{consumption: consumption})
          {:error, :expired_transaction_consumption}
      end
    else
      error when is_binary(error) ->
        {:error, String.to_existing_atom(error)}

      error when is_atom(error) ->
        {:error, error}

      error ->
        error
    end
  end

  @spec validate_only_one_exchange_address_in_pair(%TransactionRequest{}, %Wallet{} | nil) ::
          :ok | {:error, :request_already_contains_exchange}
  def validate_only_one_exchange_address_in_pair(
        %TransactionRequest{exchange_wallet_address: nil},
        nil
      ) do
    :ok
  end

  def validate_only_one_exchange_address_in_pair(
        %TransactionRequest{exchange_wallet_address: nil},
        _wallet_exchange
      ) do
    :ok
  end

  def validate_only_one_exchange_address_in_pair(
        %TransactionRequest{exchange_wallet_address: _address},
        nil
      ) do
    :ok
  end

  def validate_only_one_exchange_address_in_pair(
        %TransactionRequest{exchange_wallet_address: address},
        %Wallet{address: address}
      ) do
    :ok
  end

  def validate_only_one_exchange_address_in_pair(
        %TransactionRequest{exchange_wallet_address: _address},
        _wallet_exchange
      ) do
    {:error, :request_already_contains_exchange}
  end

  @spec validate_amount(%TransactionRequest{}, integer() | nil) ::
          {:ok, integer() | nil}
          | {:error, :unauthorized_amount_override}
          | {:error, :invalid_parameter, String.t()}
  def validate_amount(%TransactionRequest{amount: nil} = _request, nil) do
    {:error, :invalid_parameter,
     "Invalid parameter provided. `amount` is required for transaction consumption."}
  end

  def validate_amount(%TransactionRequest{amount: _amount} = _request, nil) do
    {:ok, nil}
  end

  def validate_amount(%TransactionRequest{allow_amount_override: true} = _request, amount)
      when is_binary(amount) do
    case Helper.string_to_integer(amount) do
      {:ok, amount} ->
        {:ok, amount}

      error ->
        error
    end
  end

  def validate_amount(%TransactionRequest{allow_amount_override: true} = _request, amount)
      when is_integer(amount) do
    {:ok, amount}
  end

  def validate_amount(%TransactionRequest{allow_amount_override: false} = _request, amount)
      when not is_nil(amount) do
    {:error, :unauthorized_amount_override}
  end

  def validate_amount(_request, amount) do
    {:error, :invalid_parameter,
     "Invalid parameter provided. `amount` is not an integer: #{amount}."}
  end

  @spec get_and_validate_token(%TransactionRequest{}, String.t() | nil) ::
          {:ok, %Token{}}
          | {:error, atom()}
          | {:error, atom(), String.t()}
  def get_and_validate_token(%TransactionRequest{token_uuid: nil} = _request, nil) do
    {:error, :invalid_parameter,
     "Invalid parameter provided. `token_id` is required since the transaction request does not specify any."}
  end

  def get_and_validate_token(%TransactionRequest{token_uuid: token_uuid}, nil) do
    TokenFetcher.fetch(%{"token_uuid" => token_uuid})
  end

  def get_and_validate_token(%{token_uuid: nil} = _request, token_id) do
    TokenFetcher.fetch(%{"token_id" => token_id})
  end

  def get_and_validate_token(request, token_id) do
    with {:ok, token} <- TokenFetcher.fetch(%{"token_id" => token_id}),
         request_token <- Repo.preload(request, :token).token,
         {:ok, _pair} <- fetch_pair(request.type, request_token.uuid, token.uuid) do
      {:ok, token}
    else
      error -> error
    end
  end

  @spec validate_max_consumptions_per_user(%TransactionRequest{}, %Wallet{}) ::
          {:error, :max_consumptions_per_user_reached} | {:ok, any()}
  def validate_max_consumptions_per_user(request, wallet) do
    with max <- request.max_consumptions_per_user,
         # max has a value
         false <- is_nil(max),
         # The consumption is for a user
         false <- is_nil(wallet.user_uuid),
         current_consumptions <-
           TransactionConsumption.all_active_for_user(wallet.user_uuid, request.uuid),
         false <- length(current_consumptions) < max do
      {:error, :max_consumptions_per_user_reached}
    else
      _ -> {:ok, wallet}
    end
  end

  @spec validate_max_consumptions_per_interval(%TransactionRequest{}) ::
          {:error, :max_consumptions_per_interval_reached} | {:ok, nil}
  def validate_max_consumptions_per_interval(request) do
    with max <- request.max_consumptions_per_interval,
         duration <- request.consumption_interval_duration,
         {false, false} <- {is_nil(max), is_nil(duration)},
         last_interval_end <- NaiveDateTime.add(NaiveDateTime.utc_now(), -duration, :millisecond),
         last_consumptions <-
           TransactionConsumption.get_last_confirmed_consumptions(request.uuid, last_interval_end),
         false <- length(last_consumptions) < max do
      {:error, :max_consumptions_per_interval_reached}
    else
      _ -> {:ok, nil}
    end
  end

  @spec validate_max_consumptions_per_interval_per_user(%TransactionRequest{}, %Wallet{}) ::
          {:error, :max_consumptions_per_interval_per_user_reached} | {:ok, nil}
  def validate_max_consumptions_per_interval_per_user(request, wallet) do
    with max <- request.max_consumptions_per_interval_per_user,
         duration <- request.consumption_interval_duration,
         {false, false} <- {is_nil(max), is_nil(duration)},
         false <- is_nil(wallet.user_uuid),
         last_interval_end <- NaiveDateTime.add(NaiveDateTime.utc_now(), -duration, :millisecond),
         last_consumptions <-
           TransactionConsumption.get_last_confirmed_consumptions_for_user(
             request.uuid,
             wallet.user_uuid,
             last_interval_end
           ),
         false <- length(last_consumptions) < max do
      {:error, :max_consumptions_per_interval_per_user_reached}
    else
      _ -> {:ok, wallet}
    end
  end

  defp fetch_pair(_type, request_token_uuid, consumption_token_uuid)
       when request_token_uuid == consumption_token_uuid do
    {:ok, nil}
  end

  defp fetch_pair(type, request_token_uuid, consumption_token_uuid) do
    case type do
      "send" ->
        ExchangePair.fetch_exchangable_pair(request_token_uuid, consumption_token_uuid)

      "receive" ->
        ExchangePair.fetch_exchangable_pair(consumption_token_uuid, request_token_uuid)
    end
  end
end
