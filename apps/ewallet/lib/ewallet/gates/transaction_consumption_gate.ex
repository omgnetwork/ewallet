defmodule EWallet.TransactionConsumptionGate do
  @moduledoc """
  Business logic to manage transaction request consumptions. This module is responsible for
  creating new consumptions, generating transfers and transactions. It can also be used to
  retrieve a specific consumption.

  It is basically an interface to the EWalletDB.TransactionConsumption schema.
  """
  alias EWallet.{TransactionGate, TransactionRequestGate, BalanceFetcher, Web.V1.Event}
  alias EWalletDB.{Repo, Account, MintedToken, User, Balance, TransactionConsumption}

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
    with {:ok, request} <- TransactionRequestGate.get_with_lock(request_id),
         {:ok, request} <- TransactionRequestGate.expire_if_past_expiration_date(request),
         {:ok, request} <- TransactionRequestGate.validate_request(request),
         {:ok, amount} <- TransactionRequestGate.validate_amount(request, attrs["amount"]),
         {:ok, minted_token} <- get_and_validate_minted_token(request, attrs["token_id"]),
         {:ok, consumption} <- insert(balance, minted_token, request, amount, attrs),
         {:ok, consumption} <- get(consumption.id) do
      case request.require_confirmation do
        true ->
          Event.dispatch(:transaction_consumption_request, %{consumption: consumption})
          {:ok, consumption}

        false ->
          consumption
          |> TransactionConsumption.approve()
          |> transfer(request.type)
      end
    else
      error when is_atom(error) -> {:error, error}
      error -> error
    end
  end

  defp get_and_validate_minted_token(request, nil) do
    request = request |> Repo.preload(:minted_token)
    {:ok, request.minted_token}
  end

  defp get_and_validate_minted_token(request, token_id) do
    case MintedToken.get(token_id) do
      nil -> {:error, :minted_token_not_found}
      minted_token -> validate_minted_token(request, minted_token)
    end
  end

  defp validate_minted_token(request, minted_token) do
    case request.minted_token_id == minted_token.id do
      true -> {:ok, minted_token}
      false -> {:error, :invalid_minted_token_provided}
    end
  end

  defp validate_consumption(consumption) do
    {:ok, consumption} = TransactionConsumption.expire_if_past_expiration_date(consumption)

    case TransactionConsumption.expired?(consumption) do
      false -> {:ok, consumption}
      true -> {:error, :expired_transaction_consumption}
    end
  end

  @spec get(UUID.t()) ::
          {:ok, TransactionConsumption.t()}
          | {:error, :transaction_consumption_not_found}
  def get(id) do
    consumption =
      TransactionConsumption.get(
        id,
        preload: [
          :account,
          :user,
          :balance,
          :minted_token,
          :transaction_request,
          :transfer
        ]
      )

    case consumption do
      nil -> {:error, :transaction_consumption_not_found}
      consumption -> {:ok, consumption}
    end
  end

  @spec confirm(UUID.t(), Boolean.t(), Map.t()) ::
          {:ok, TransactionConsumption.t()}
          | {:error, Atom.t()}
          | {:error, TransactionConsumption.t(), Atom.t(), String.t()}
  def confirm(id, approved, owner) do
    transaction = Repo.transaction(fn -> do_confirm(id, approved, owner) end)

    case transaction do
      {:ok, res} -> res
      {:error, error} -> {:error, error}
    end
  end

  defp do_confirm(id, approved, owner) do
    with {:ok, consumption} <- get(id),
         {:ok, request} <-
           TransactionRequestGate.get_with_lock(consumption.transaction_request.id),
         true <-
           TransactionRequestGate.is_owner?(request, owner) ||
             {:error, :not_transaction_request_owner},
         {:ok, request} <- TransactionRequestGate.validate_request(request),
         {:ok, consumption} <- validate_consumption(consumption) do
      case approved do
        true ->
          consumption
          |> TransactionConsumption.approve()
          |> transfer(request.type)

        false ->
          consumption = TransactionConsumption.reject(consumption)
          {:ok, consumption}
      end
    else
      error -> error
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
      expiration_date: TransactionRequestGate.expiration_from_lifetime(request),
      metadata: attrs["metadata"] || %{},
      encrypted_metadata: attrs["encrypted_metadata"] || %{}
    })
  end

  defp transfer(consumption, "send") do
    from = consumption.transaction_request.balance_address
    to = consumption.balance.address
    transfer(consumption, from, to)
  end

  defp transfer(consumption, "receive") do
    from = consumption.balance.address
    to = consumption.transaction_request.balance_address
    transfer(consumption, from, to)
  end

  defp transfer(consumption, from, to) do
    attrs = %{
      "idempotency_token" => consumption.idempotency_token,
      "from_address" => from,
      "to_address" => to,
      "token_id" => consumption.minted_token.id,
      "amount" => consumption.amount,
      "metadata" => consumption.metadata,
      "encrypted_metadata" => consumption.encrypted_metadata
    }

    case TransactionGate.process_with_addresses(attrs) do
      {:ok, transfer, _, _} ->
        # Expires the request if it has reached the max number of consumptions (only CONFIRMED
        # SUCCESSFUL) consumptions are accounted for.
        consumption = TransactionConsumption.confirm(consumption, transfer)

        request = consumption.transaction_request
        {:ok, request} = TransactionRequestGate.expire_if_max_consumption(request)

        consumption =
          consumption
          |> Map.put(:transaction_request_id, request.id)
          |> Map.put(:transaction_request, request)

        {:ok, consumption}

      {:error, transfer, code, description} ->
        consumption = TransactionConsumption.fail(consumption, transfer)
        {:error, consumption, code, description}
    end
  end
end
