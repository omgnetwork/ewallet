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

defmodule EWalletAPI.V1.TransactionConsumptionController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.Web.{Orchestrator, Originator, V1.TransactionConsumptionOverlay}

  alias EWallet.{
    TransactionConsumptionConfirmerGate,
    TransactionConsumptionConsumerGate,
    TransactionConsumptionFetcher,
    TransactionConsumptionPolicy,
    Web.V1.Event
  }

  alias EWalletDB.TransactionConsumption

  def consume_for_user(conn, %{"idempotency_token" => idempotency_token} = attrs)
      when idempotency_token != nil do
    attrs =
      attrs
      |> Map.delete("exchange_account_id")
      |> Map.delete("exchange_wallet_address")
      |> Map.put("originator", Originator.extract(conn.assigns))

    with {:ok, consumption} <-
           TransactionConsumptionConsumerGate.consume(conn.assigns.end_user, attrs) do
      consumption
      |> Orchestrator.one(TransactionConsumptionOverlay, attrs)
      |> respond(conn, true)
    else
      error ->
        respond(error, conn, true)
    end
  end

  def consume_for_user(conn, _) do
    handle_error(
      conn,
      :invalid_parameter,
      "Invalid parameter provided. `idempotency_token` is required"
    )
  end

  def cancel_for_user(conn, %{"id" => id} = attrs) do
    with {:ok, consumption} <- TransactionConsumptionFetcher.get(id),
         {:ok, _} <- TransactionConsumptionPolicy.authorize(:cancel, conn.assigns, consumption),
         true <-
           TransactionConsumption.cancellable?(consumption) ||
             {:error, :uncancellable_transaction_consumption},
         %TransactionConsumption{} = consumption <-
           TransactionConsumption.cancel(consumption, Originator.extract(conn.assigns)) do
      consumption
      |> Orchestrator.one(TransactionConsumptionOverlay, attrs)
      |> respond(conn, true)
    else
      error ->
        respond(error, conn, true)
    end
  end

  def cancel_for_user(conn, _) do
    handle_error(conn, :invalid_parameter, "Invalid parameter provided. `id` is required")
  end

  def approve_for_user(conn, attrs), do: confirm(conn, conn.assigns.end_user, attrs, true)
  def reject_for_user(conn, attrs), do: confirm(conn, conn.assigns.end_user, attrs, false)

  defp confirm(conn, user, %{"id" => id} = attrs, approved) do
    id
    |> TransactionConsumptionConfirmerGate.confirm(
      approved,
      %{end_user: user},
      Originator.extract(conn.assigns)
    )
    |> case do
      {:ok, consumption} ->
        consumption
        |> Orchestrator.one(TransactionConsumptionOverlay, attrs)
        |> respond(conn, true)

      error ->
        respond(error, conn, true)
    end
  end

  defp confirm(conn, _entity, _attrs, _approved), do: handle_error(conn, :invalid_parameter)

  defp respond({:error, error}, conn, _dispatch?) when is_atom(error) do
    handle_error(conn, error)
  end

  defp respond({:error, consumption, code, description}, conn, true) do
    dispatch_confirm_event(consumption)
    handle_error(conn, code, description)
  end

  defp respond({:error, _consumption, code, description}, conn, false) do
    handle_error(conn, code, description)
  end

  defp respond({:ok, consumption}, conn, true) do
    dispatch_confirm_event(consumption)
    respond({:ok, consumption}, conn, false)
  end

  defp respond({:ok, consumption}, conn, false) do
    render(conn, :transaction_consumption, %{transaction_consumption: consumption})
  end

  defp dispatch_confirm_event(consumption) do
    if TransactionConsumption.finalized?(consumption) do
      Event.dispatch(:transaction_consumption_finalized, %{consumption: consumption})
    end
  end
end
