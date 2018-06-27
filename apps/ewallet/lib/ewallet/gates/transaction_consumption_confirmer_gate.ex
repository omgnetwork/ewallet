defmodule EWallet.TransactionConsumptionConfirmerGate do
  @moduledoc """
  Handles all confirmations-related actions on transaction consumptions.

  This module is responsible for finalizing (approving/rejecting) transaction
  consumptions and initiating the actual transfer of funds.
  """
  alias EWallet.{
    TransactionGate,
    TransactionRequestFetcher,
    TransactionConsumptionFetcher,
    TransactionConsumptionValidator
  }

  alias EWalletDB.{Repo, TransactionRequest, TransactionConsumption}

  @spec approve_and_confirm(TransactionRequest.t(), TransactionConsumption.t()) ::
          {:ok, TransactionConsumption.t()}
          | {:error, TransactionConsumption.t(), Atom.t(), String.t()}
          | {:error, TransactionConsumption.t(), String.t(), String.t()}
  def approve_and_confirm(request, consumption) do
    consumption
    |> TransactionConsumption.approve()
    |> transfer(request.type)
  end

  @spec confirm(UUID.t(), Boolean.t(), Map.t()) ::
          {:ok, TransactionConsumption.t()}
          | {:error, Atom.t()}
          | {:error, TransactionConsumption.t(), Atom.t(), String.t()}
  def confirm(id, approved, owner) do
    transaction = Repo.transaction(fn -> do_confirm(id, approved, owner) end)

    case transaction do
      {:ok, res} -> res
      {:error, _changeset} = error -> error
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  defp do_confirm(id, approved, owner) do
    with {v, f} <- {TransactionConsumptionValidator, TransactionConsumptionFetcher},
         {:ok, consumption} <- f.get(id),
         request <- consumption.transaction_request,
         {:ok, request} <- TransactionRequestFetcher.get_with_lock(request.id),
         {:ok, consumption} <- v.validate_before_confirmation(consumption, owner) do
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

  defp transfer(consumption, "send") do
    from = consumption.transaction_request.wallet_address
    to = consumption.wallet.address
    transfer(consumption, from, to)
  end

  defp transfer(consumption, "receive") do
    from = consumption.wallet.address
    to = consumption.transaction_request.wallet_address
    transfer(consumption, from, to)
  end

  defp transfer(consumption, from, to) do
    attrs = %{
      "idempotency_token" => consumption.idempotency_token,
      "from_address" => from,
      "to_address" => to,
      "token_id" => consumption.token.id,
      "amount" => consumption.amount,
      "metadata" => consumption.metadata,
      "encrypted_metadata" => consumption.encrypted_metadata
    }

    case TransactionGate.create(attrs) do
      {:ok, transaction} ->
        # Expires the request if it has reached the max number of consumptions (only CONFIRMED
        # SUCCESSFUL) consumptions are accounted for.
        consumption = TransactionConsumption.confirm(consumption, transaction)

        request = consumption.transaction_request
        {:ok, request} = TransactionRequest.expire_if_max_consumption(request)

        consumption =
          consumption
          |> Map.put(:transaction_request_id, request.id)
          |> Map.put(:transaction_request, request)

        {:ok, consumption}

      {:error, transaction, code, description} ->
        consumption = TransactionConsumption.fail(consumption, transaction)
        {:error, consumption, code, description}
    end
  end
end
