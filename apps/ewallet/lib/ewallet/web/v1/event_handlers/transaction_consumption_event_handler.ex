defmodule EWallet.Web.V1.TransactionConsumptionEventHandler do
  @moduledoc """
  This module represents the transaction_consumption_confirmation event and how to build it.
  """
  alias EWallet.Web.V1.{Event, TransactionConsumptionSerializer}
  alias EWalletDB.Helpers.{Assoc, Preloader}
  alias EWalletDB.TransactionConsumption

  @spec broadcast(Atom.t(), TransactionConsumption.t()) :: :ok | {:error, :unhandled_event}
  def broadcast(:transaction_consumption_request, %{consumption: consumption}) do
    consumption = Preloader.preload(consumption, transaction_request: [:account, :user])

    topics =
      []
      |> Event.address_topic(Assoc.get(consumption, [:transaction_request, :wallet_address]))
      |> Event.transaction_request_topic(Assoc.get(consumption, [:transaction_request, :id]))
      |> Event.user_topic(Assoc.get(consumption, [:transaction_request, :user, :id]))
      |> Event.account_topic(Assoc.get(consumption, [:transaction_request, :account, :id]))

    Event.broadcast(
      event: "transaction_consumption_request",
      topics: topics,
      payload: %{
        status: :ok,
        data: TransactionConsumptionSerializer.serialize(consumption)
      }
    )
  end

  def broadcast(:transaction_consumption_finalized, %{consumption: consumption}) do
    broadcast_change("transaction_consumption_finalized", consumption)
  end

  def broadcast(_, _), do: {:error, :unhandled_event}

  defp broadcast_change(event, consumption) do
    consumption = Preloader.preload(consumption, [:account, :transaction_request, :user])
    transaction_request = Preloader.preload(consumption.transaction_request, [:account, :user])
    request_user_id = Assoc.get(transaction_request, [:user, :id])
    consumption_user_id = Assoc.get(consumption, [:user, :id])
    request_account_id = Assoc.get(transaction_request, [:account, :id])
    consumption_account_id = Assoc.get(consumption, [:account, :id])

    topics =
      []
      |> Event.transaction_request_topic(Assoc.get(consumption, [:transaction_request, :id]))
      |> Event.transaction_consumption_topic(consumption.id)
      |> add_topic_if_different(
        transaction_request.wallet_address,
        consumption.wallet_address,
        &Event.address_topic/2
      )
      |> add_topic_if_different(request_user_id, consumption_user_id, &Event.user_topic/2)
      |> add_topic_if_different(
        request_account_id,
        consumption_account_id,
        &Event.account_topic/2
      )

    Event.broadcast(
      event: event,
      topics: topics,
      payload: payload(consumption)
    )
  end

  defp add_topic_if_different(topics, value_1, value_2, topic_fun) when value_1 == value_2 do
    topic_fun.(topics, value_1)
  end

  defp add_topic_if_different(topics, value_1, value_2, topic_fun) do
    topics
    |> topic_fun.(value_1)
    |> topic_fun.(value_2)
  end

  defp payload(consumption) do
    case TransactionConsumption.success?(consumption) do
      true ->
        %{
          status: :ok,
          data: TransactionConsumptionSerializer.serialize(consumption)
        }

      false ->
        %{
          status: :error,
          error: error_code(consumption),
          data: TransactionConsumptionSerializer.serialize(consumption)
        }
    end
  end

  defp error_code(consumption) do
    consumption = Preloader.preload(consumption, :transaction)

    case consumption.status do
      "failed" ->
        %{
          code: consumption.error_code || Assoc.get(consumption, [:transaction, :error_code]),
          description:
            consumption.error_description ||
              Assoc.get(consumption, [:transaction, :error_description]) ||
              Assoc.get(consumption, [:transaction, :error_data])
        }

      "expired" ->
        :expired_transaction_consumption

      "pending" ->
        :unfinalized_transaction_consumption
    end
  end
end
