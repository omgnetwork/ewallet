defmodule EWallet.TransactionConsumptionConsumerGate do
  @moduledoc """
  Handles all consumptions-related actions on transaction requests.

  This module is responsible for consuming a transaction request after
  having validated its content.
  """
  alias EWallet.{
    BalanceFetcher,
    TransactionRequestFetcher,
    TransactionConsumptionFetcher,
    TransactionConsumptionValidator,
    TransactionConsumptionConfirmerGate,
    TransactionRequestValidator
  }

  alias EWallet.Web.V1.Event

  alias EWalletDB.{Repo, Balance, Account, User, TransactionConsumption}

  @spec consume(Map.t()) :: {:ok, TransactionConsumption.t()} | {:error, Atom.t()}
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
         {:ok, balance} <- BalanceFetcher.get(user, address),
         balance <- Map.put(balance, :account_id, account.id) do
      consume(balance, attrs)
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
         {:ok, balance} <- BalanceFetcher.get(account, address) do
      consume(balance, attrs)
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
         {:ok, balance} <- BalanceFetcher.get(user, address) do
      consume(balance, attrs)
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

  def consume(
        %{
          "address" => address
        } = attrs
      ) do
    with {:ok, balance} <- BalanceFetcher.get(nil, address) do
      consume(balance, attrs)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def consume(_attrs), do: {:error, :invalid_parameter}

  @spec consume(User.t(), Map.t()) :: {:ok, TransactionConsumption.t()} | {:error, Atom.t()}
  def consume(
        %User{} = user,
        %{
          "address" => address
        } = attrs
      ) do
    with {:ok, balance} <- BalanceFetcher.get(user, address) do
      consume(balance, attrs)
    else
      error -> error
    end
  end

  @spec consume(Balance.t(), Map.t()) :: {:ok, TransactionConsumption.t()} | {:error, Atom.t()}
  def consume(
        %Balance{} = balance,
        %{
          "transaction_request_id" => _,
          "idempotency_token" => _
        } = attrs
      ) do
    transaction = Repo.transaction(fn -> do_consume(balance, attrs) end)

    case transaction do
      {:ok, res} -> res
      {:error, error} -> {:error, error}
    end
  end

  def consume(_, _attrs), do: {:error, :invalid_parameter}

  defp do_consume(
         balance,
         %{
           "transaction_request_id" => request_id
         } = attrs
       ) do
    with {:ok, request} <- TransactionRequestFetcher.get_with_lock(request_id),
         {:ok, nil} <- TransactionConsumptionFetcher.idempotent_fetch(attrs["idempotency_token"]),
         {:ok, request} <- TransactionRequestValidator.validate_request(request),
         {:ok, amount} <- TransactionRequestValidator.validate_amount(request, attrs["amount"]),
         {:ok, balance} <-
           TransactionConsumptionValidator.validate_max_consumptions_per_user(request, balance),
         {:ok, minted_token} <-
           TransactionConsumptionValidator.get_and_validate_minted_token(
             request,
             attrs["token_id"]
           ),
         {:ok, consumption} <- insert(balance, minted_token, request, amount, attrs),
         {:ok, consumption} <- TransactionConsumptionFetcher.get(consumption.id) do
      case request.require_confirmation do
        true ->
          Event.dispatch(:transaction_consumption_request, %{consumption: consumption})
          {:ok, consumption}

        false ->
          TransactionConsumptionConfirmerGate.approve_and_confirm(request, consumption)
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

  defp insert(balance, minted_token, request, amount, attrs) do
    TransactionConsumption.insert(%{
      correlation_id: attrs["correlation_id"],
      idempotency_token: attrs["idempotency_token"],
      amount: amount,
      user_uuid: balance.user_uuid,
      account_uuid: balance.account_uuid,
      minted_token_uuid: minted_token.uuid,
      transaction_request_uuid: request.uuid,
      balance_address: balance.address,
      expiration_date: TransactionRequestValidator.expiration_from_lifetime(request),
      metadata: attrs["metadata"] || %{},
      encrypted_metadata: attrs["encrypted_metadata"] || %{}
    })
  end
end
