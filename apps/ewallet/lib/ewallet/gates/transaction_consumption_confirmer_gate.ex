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
    TransactionConsumptionValidator,
    Web.V1.ErrorHandler
  }

  alias EWalletDB.{Repo, TransactionRequest, TransactionConsumption, Helpers.Assoc}
  alias Ecto.Changeset

  @spec approve_and_confirm(TransactionRequest.t(), TransactionConsumption.t()) ::
          {:ok, TransactionConsumption.t()}
          | {:error, TransactionConsumption.t(), Atom.t(), String.t()}
          | {:error, TransactionConsumption.t(), String.t(), String.t()}
  def approve_and_confirm(request, consumption) do
    consumption
    |> TransactionConsumption.approve()
    |> transfer(request)
  end

  @spec confirm(UUID.t(), Boolean.t(), Map.t()) ::
          {:ok, TransactionConsumption.t()}
          | {:error, Atom.t()}
          | {:error, TransactionConsumption.t(), Atom.t(), String.t()}
  def confirm(id, approved, confirmer) do
    transaction = Repo.transaction(fn -> do_confirm(id, approved, confirmer) end)

    case transaction do
      {:ok, res} -> res
      {:error, _changeset} = error -> error
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  defp do_confirm(id, approved, confirmer) do
    with {v, f} <- {TransactionConsumptionValidator, TransactionConsumptionFetcher},
         {:ok, consumption} <- f.get(id),
         request <- consumption.transaction_request,
         {:ok, request} <- TransactionRequestFetcher.get_with_lock(request.id),
         {:ok, consumption} <- v.validate_before_confirmation(consumption, confirmer) do
      case approved do
        true ->
          consumption
          |> TransactionConsumption.approve()
          |> transfer(request)

        false ->
          consumption = TransactionConsumption.reject(consumption)
          {:ok, consumption}
      end
    else
      error -> error
    end
  end

  defp transfer(
         %TransactionConsumption{token_uuid: from_token_uuid} = consumption,
         %{type: "send", token_uuid: to_token_uuid} = request
       )
       when from_token_uuid == to_token_uuid do
    do_transfer(consumption, request, %{
      from: %{
        address: request.wallet_address,
        token_id: consumption.token.id,
        amount: consumption.estimated_request_amount
      },
      to: %{
        address: consumption.wallet_address,
        token_id: consumption.token.id,
        amount: consumption.estimated_consumption_amount
      }
    })
  end

  defp transfer(
         %TransactionConsumption{token_uuid: _from_token_uuid} = consumption,
         %{type: "send", token_uuid: _to_token_uuid} = request
       ) do
    do_transfer(consumption, request, %{
      from: %{
        address: request.wallet_address,
        token_id: request.token.id,
        amount: consumption.estimated_request_amount
      },
      to: %{
        address: consumption.wallet_address,
        token_id: consumption.token.id,
        amount: consumption.estimated_consumption_amount
      }
    })
  end

  defp transfer(
         %TransactionConsumption{token_uuid: from_token_uuid} = consumption,
         %{type: "receive", token_uuid: to_token_uuid} = request
       )
       when from_token_uuid == to_token_uuid do
    do_transfer(consumption, request, %{
      from: %{
        address: consumption.wallet_address,
        token_id: consumption.token.id,
        amount: consumption.estimated_consumption_amount
      },
      to: %{
        address: request.wallet_address,
        token_id: consumption.token.id,
        amount: consumption.estimated_request_amount
      }
    })
  end

  defp transfer(
         %TransactionConsumption{token_uuid: _from_token_uuid} = consumption,
         %{type: "receive", token_uuid: _to_token_uuid} = request
       ) do
    do_transfer(consumption, request, %{
      from: %{
        address: consumption.wallet_address,
        token_id: consumption.token.id,
        amount: consumption.estimated_consumption_amount
      },
      to: %{
        address: request.wallet_address,
        token_id: request.token.id,
        amount: consumption.estimated_request_amount
      }
    })
  end

  defp transfer(consumption, %{type: "receive"} = request) do
    do_transfer(consumption, request, %{
      from: %{
        address: consumption.wallet_address,
        token_id: consumption.token.id,
        amount: consumption.amount
      },
      to: %{
        address: request.wallet_address,
        token_id: request.token.id,
        amount: request.amount
      }
    })
  end

  defp do_transfer(consumption, request, data) do
    attrs = %{
      "idempotency_token" => consumption.idempotency_token,
      "from_address" => data.from.address,
      "to_address" => data.to.address,
      "from_token_id" => data.from.token_id,
      "to_token_id" => data.to.token_id,
      "from_amount" => data.from.amount,
      "to_amount" => data.to.amount,
      "metadata" => consumption.metadata,
      "encrypted_metadata" => consumption.encrypted_metadata,
      "exchange_account_id" =>
        Assoc.get(request, [:exchange_account, :id]) ||
          Assoc.get(consumption, [:exchange_account, :id]),
      "exchange_wallet_address" =>
        Assoc.get(request, [:exchange_wallet, :address]) ||
          Assoc.get(consumption, [:exchange_wallet, :address])
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

      {:error, %Changeset{} = changeset} ->
        error = ErrorHandler.build_error(:invalid_parameter, changeset, ErrorHandler.errors())
        consumption = TransactionConsumption.fail(consumption, error.code, error.description)
        {:error, consumption, :invalid_parameter, error.description}

      {:error, code} ->
        error = ErrorHandler.build_error(code, ErrorHandler.errors())
        consumption = TransactionConsumption.fail(consumption, error.code, error.description)
        {:error, consumption, code}

      {:error, code, description} ->
        consumption = TransactionConsumption.fail(consumption, code, description)
        {:error, consumption, code, description}

      {:error, transaction, code, description} ->
        consumption = TransactionConsumption.fail(consumption, transaction)
        {:error, consumption, code, description}
    end
  end
end
