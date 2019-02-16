# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EWallet.TransactionConsumptionConsumerGate do
  @moduledoc """
  Handles all consumptions-related actions on transaction requests.

  This module is responsible for consuming a transaction request after
  having validated its content.
  """
  alias EWallet.{
    Exchange,
    ExchangeAccountFetcher,
    TransactionConsumptionConfirmerGate,
    TransactionConsumptionFetcher,
    TransactionConsumptionValidator,
    TransactionRequestFetcher,
    WalletFetcher
  }

  alias EWallet.Web.V1.Event
  alias Utils.Helpers.Assoc

  alias EWalletDB.{
    Account,
    Repo,
    TransactionConsumption,
    TransactionRequest,
    User,
    Wallet
  }

  alias ActivityLogger.System

  @spec consume(map()) ::
          {:ok, %TransactionConsumption{}}
          | {:error, %TransactionConsumption{}}
          | {:error, atom()}
          | {:error, atom(), String.t()}
  def consume(
        %{
          "account_id" => account_id,
          "provider_user_id" => provider_user_id,
          "address" => address
        } = attrs
      ) do
    with %Account{} = account <- Account.get(account_id) || :account_id_not_found,
         %User{} = user <-
           User.get_by_provider_user_id(provider_user_id) || :provider_user_id_not_found,
         {:ok, wallet} <- WalletFetcher.get(user, address),
         wallet <- Map.put(wallet, :account_id, account.id) do
      consume(wallet, attrs)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def consume(
        %{
          "account_id" => account_id,
          "user_id" => user_id,
          "address" => address
        } = attrs
      ) do
    with %Account{} = account <- Account.get(account_id) || :account_id_not_found,
         %User{} = user <- User.get(user_id) || :provider_user_id_not_found,
         {:ok, wallet} <- WalletFetcher.get(user, address),
         wallet <- Map.put(wallet, :account_id, account.id) do
      consume(wallet, attrs)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def consume(
        %{
          "account_id" => account_id,
          "address" => address
        } = attrs
      ) do
    with %Account{} = account <- Account.get(account_id) || :account_id_not_found,
         {:ok, wallet} <- WalletFetcher.get(account, address) do
      consume(wallet, attrs)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def consume(%{"account_id" => _} = attrs) do
    attrs
    |> Map.put("address", nil)
    |> consume()
  end

  def consume(
        %{
          "provider_user_id" => provider_user_id,
          "address" => address
        } = attrs
      ) do
    with %User{} = user <-
           User.get_by_provider_user_id(provider_user_id) || :provider_user_id_not_found,
         {:ok, wallet} <- WalletFetcher.get(user, address) do
      consume(wallet, attrs)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def consume(
        %{
          "user_id" => user_id,
          "address" => address
        } = attrs
      ) do
    with %User{} = user <- User.get(user_id) || :provider_user_id_not_found,
         {:ok, wallet} <- WalletFetcher.get(user, address) do
      consume(wallet, attrs)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def consume(%{"provider_user_id" => _} = attrs) do
    attrs
    |> Map.put("address", nil)
    |> consume()
  end

  def consume(%{"user_id" => _} = attrs) do
    attrs
    |> Map.put("address", nil)
    |> consume()
  end

  def consume(
        %{
          "address" => address
        } = attrs
      ) do
    with {:ok, wallet} <- WalletFetcher.get(nil, address) do
      consume(wallet, attrs)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def consume(_attrs), do: {:error, :invalid_parameter}

  @spec consume(%User{} | %Wallet{}, map()) ::
          {:ok, %TransactionConsumption{}} | {:error, atom()} | {:error, atom(), String.t()}
  def consume(
        %User{} = user,
        %{
          "formatted_transaction_request_id" => formatted_transaction_request_id,
          "token_id" => token_id
        } = attrs
      )
      when not is_nil(token_id) do
    with {:ok, wallet} <- WalletFetcher.get(user, attrs["address"]),
         {:ok, request} <- TransactionRequestFetcher.get(formatted_transaction_request_id),
         true <- request.token.id == token_id || :exchange_client_not_allowed do
      consume(wallet, attrs)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def consume(
        %User{} = user,
        attrs
      ) do
    with {:ok, wallet} <- WalletFetcher.get(user, attrs["address"]) do
      consume(wallet, attrs)
    else
      error -> error
    end
  end

  def consume(
        %Wallet{} = wallet,
        %{
          "formatted_transaction_request_id" => _,
          "idempotency_token" => _
        } = attrs
      ) do
    transaction = Repo.transaction(fn -> do_consume(wallet, attrs) end)

    case transaction do
      {:ok, res} ->
        res

      {:error, _changeset} = error ->
        error

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  def consume(_, _attrs), do: {:error, :invalid_parameter}

  defp do_consume(
         wallet,
         %{
           "formatted_transaction_request_id" => formatted_request_id,
           "idempotency_token" => idempotency_token
         } = attrs
       ) do
    with {v, f} <- {TransactionConsumptionValidator, TransactionConsumptionFetcher},
         {:ok, request} <- TransactionRequestFetcher.get_with_lock(formatted_request_id),
         {:ok, nil} <- f.idempotent_fetch(idempotency_token),
         {:ok, exchange_wallet} <- ExchangeAccountFetcher.fetch(attrs),
         {:ok, request, token, amount} <-
           v.validate_before_consumption(request, wallet, attrs, exchange_wallet),
         {:ok, consumption} <- insert(wallet, exchange_wallet, token, request, amount, attrs),
         {:ok, consumption} <- f.get(consumption.id) do
      case request.require_confirmation do
        true ->
          Event.dispatch(:transaction_consumption_request, %{consumption: consumption})
          {:ok, consumption}

        false ->
          TransactionConsumptionConfirmerGate.approve_and_confirm(request, consumption, %System{})
      end
    else
      {:idempotent_call, consumption} ->
        {:ok, consumption}

      error when is_atom(error) ->
        {:error, error}

      error ->
        error
    end
  end

  defp insert(wallet, exchange_wallet, token, request, amount, attrs) do
    case get_calculation(request, amount, token) do
      {:ok, calculation, amounts} ->
        TransactionConsumption.insert(%{
          correlation_id: attrs["correlation_id"],
          idempotency_token: attrs["idempotency_token"],
          amount: amount,
          user_uuid: wallet.user_uuid,
          account_uuid: wallet.account_uuid,
          token_uuid: token.uuid,
          transaction_request_uuid: request.uuid,
          wallet_address: wallet.address,
          exchange_account_uuid: Assoc.get_if_exists(exchange_wallet, [:account_uuid]),
          exchange_wallet_address: Assoc.get_if_exists(exchange_wallet, [:address]),
          expiration_date: TransactionRequest.expiration_from_lifetime(request),
          exchange_pair_uuid: Assoc.get(calculation, [:pair, :uuid]),
          estimated_request_amount: amounts[:request_amount],
          estimated_consumption_amount: amounts[:consumption_amount],
          estimated_at: Map.get(calculation, :calculated_at),
          estimated_rate: Map.get(calculation, :actual_rate),
          metadata: attrs["metadata"] || %{},
          encrypted_metadata: attrs["encrypted_metadata"] || %{},
          originator: attrs["originator"]
        })

      error ->
        error
    end
  end

  defp get_calculation(%TransactionRequest{allow_amount_override: true} = request, nil, token) do
    do_calculation(request.type, request.amount, request.token, nil, token)
  end

  defp get_calculation(%TransactionRequest{allow_amount_override: true} = request, amount, token) do
    do_calculation(request.type, nil, request.token, amount, token)
  end

  defp get_calculation(
         %TransactionRequest{allow_amount_override: false} = request,
         _amount,
         token
       ) do
    do_calculation(request.type, request.amount, request.token, nil, token)
  end

  defp do_calculation("send", request_amount, request_token, amount, token) do
    with {:ok, calculation} <- Exchange.calculate(request_amount, request_token, amount, token) do
      {:ok, calculation,
       %{
         request_amount: calculation.from_amount,
         consumption_amount: calculation.to_amount
       }}
    else
      error -> error
    end
  end

  defp do_calculation("receive", request_amount, request_token, amount, token) do
    with {:ok, calculation} <- Exchange.calculate(amount, token, request_amount, request_token) do
      {:ok, calculation,
       %{
         request_amount: calculation.to_amount,
         consumption_amount: calculation.from_amount
       }}
    else
      error -> error
    end
  end
end
