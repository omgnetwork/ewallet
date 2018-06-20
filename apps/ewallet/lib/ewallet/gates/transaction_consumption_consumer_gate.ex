defmodule EWallet.TransactionConsumptionConsumerGate do
  @moduledoc """
  Handles all consumptions-related actions on transaction requests.

  This module is responsible for consuming a transaction request after
  having validated its content.
  """
  alias EWallet.{
    WalletFetcher,
    TransactionRequestFetcher,
    TransactionConsumptionFetcher,
    TransactionConsumptionValidator,
    TransactionConsumptionConfirmerGate
  }

  alias EWallet.Web.V1.Event

  alias EWalletDB.{Repo, Wallet, Account, User, TransactionRequest, TransactionConsumption}

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
    with {:ok, wallet} <- WalletFetcher.get(nil, address) do
      consume(wallet, attrs)
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  def consume(_attrs), do: {:error, :invalid_parameter}

  @spec consume(User.t() | Balance.t(), Map.t()) ::
          {:ok, TransactionConsumption.t()} | {:error, Atom.t()}
  def consume(
        %User{} = user,
        %{
          "address" => address
        } = attrs
      ) do
    with {:ok, wallet} <- WalletFetcher.get(user, address) do
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
      {:ok, res} -> res
      {:error, _changeset} = error -> error
      {:error, _, changeset, _} -> {:error, changeset}
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
         {:ok, request, token, amount} <- v.validate_before_consumption(request, wallet, attrs),
         {:ok, consumption} <- insert(wallet, token, request, amount, attrs),
         {:ok, consumption} <- f.get(consumption.id) do
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

  defp insert(wallet, token, request, amount, attrs) do
    TransactionConsumption.insert(%{
      correlation_id: attrs["correlation_id"],
      idempotency_token: attrs["idempotency_token"],
      amount: amount,
      user_uuid: wallet.user_uuid,
      account_uuid: wallet.account_uuid,
      token_uuid: token.uuid,
      transaction_request_uuid: request.uuid,
      wallet_address: wallet.address,
      expiration_date: TransactionRequest.expiration_from_lifetime(request),
      metadata: attrs["metadata"] || %{},
      encrypted_metadata: attrs["encrypted_metadata"] || %{}
    })
  end
end
