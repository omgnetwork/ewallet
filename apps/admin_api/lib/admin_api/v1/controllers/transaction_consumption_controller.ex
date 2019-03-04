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

defmodule AdminAPI.V1.TransactionConsumptionController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AccountHelper
  alias EWallet.TransactionConsumptionPolicy
  alias EWallet.Web.{Orchestrator, Originator, Paginator, V1.TransactionConsumptionOverlay}

  alias EWallet.{
    TransactionConsumptionConfirmerGate,
    TransactionConsumptionConsumerGate,
    TransactionConsumptionFetcher,
    UserFetcher,
    Web.V1.Event
  }

  alias EWalletDB.{Account, TransactionConsumption, TransactionRequest, User, Wallet}

  def all_for_account(conn, %{"id" => account_id, "owned" => true} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account) do
      TransactionConsumption
      |> TransactionConsumption.query_all_for_account_uuids_and_users([account.uuid])
      |> do_all(attrs, conn)
    else
      error -> respond(error, conn, false)
    end
  end

  def all_for_account(conn, %{"id" => account_id} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account),
         descendant_uuids <- Account.get_all_descendants_uuids(account) do
      TransactionConsumption
      |> TransactionConsumption.query_all_for_account_uuids_and_users(descendant_uuids)
      |> do_all(attrs, conn)
    else
      error -> respond(error, conn, false)
    end
  end

  def all_for_account(conn, _) do
    handle_error(conn, :invalid_parameter, "Invalid parameter provided. `id` is required.")
  end

  def all_for_user(conn, attrs) do
    with {:ok, %User{} = user} <- UserFetcher.fetch(attrs),
         :ok <- permit(:all, conn.assigns, user) do
      :user_uuid
      |> TransactionConsumption.query_all_for(user.uuid)
      |> do_all(attrs, conn)
    else
      {:error, :invalid_parameter} ->
        handle_error(
          conn,
          :invalid_parameter,
          "Invalid parameter provided. `user_id` or `provider_user_id` is required."
        )

      error ->
        respond(error, conn, false)
    end
  end

  def all_for_transaction_request(
        conn,
        %{"formatted_transaction_request_id" => formatted_transaction_request_id} = attrs
      ) do
    with %TransactionRequest{} = transaction_request <-
           TransactionRequest.get(formatted_transaction_request_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, transaction_request) do
      :transaction_request_uuid
      |> TransactionConsumption.query_all_for(transaction_request.uuid)
      |> do_all(attrs, conn)
    else
      error -> respond(error, conn, false)
    end
  end

  def all_for_transaction_request(conn, _) do
    handle_error(
      conn,
      :invalid_parameter,
      "Invalid parameter provided. `formatted_transaction_request_id` is required."
    )
  end

  def all_for_wallet(conn, %{"address" => address} = attrs) do
    with %Wallet{} = wallet <- Wallet.get(address) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, wallet) do
      :wallet_address
      |> TransactionConsumption.query_all_for(wallet.address)
      |> do_all(attrs, conn)
    else
      error -> respond(error, conn, false)
    end
  end

  def all_for_wallet(conn, _) do
    handle_error(conn, :invalid_parameter, "Invalid parameter provided. `address` is required.")
  end

  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns, nil),
         account_uuids <- AccountHelper.get_accessible_account_uuids(conn.assigns),
         descendant_uuids <- Account.get_all_descendants_uuids(account_uuids) do
      TransactionConsumption
      |> TransactionConsumption.query_all_for_account_uuids_and_users(descendant_uuids)
      |> do_all(attrs, conn)
    else
      error -> respond(error, conn, false)
    end
  end

  defp do_all(query, attrs, conn) do
    query
    |> Orchestrator.query(TransactionConsumptionOverlay, attrs)
    |> respond_multiple(conn)
  end

  def get(conn, %{"id" => id} = attrs) do
    with {:ok, consumption} <- TransactionConsumptionFetcher.get(id),
         :ok <- permit(:get, conn.assigns, consumption) do
      consumption
      |> Orchestrator.one(TransactionConsumptionOverlay, attrs)
      |> respond(conn, false)
    else
      error ->
        respond(error, conn, false)
    end
  end

  def consume(conn, %{"idempotency_token" => idempotency_token} = attrs)
      when idempotency_token != nil do
    with attrs <- Originator.set_in_attrs(attrs, conn.assigns),
         {:ok, consumption} <- TransactionConsumptionConsumerGate.consume(attrs) do
      consumption
      |> Orchestrator.one(TransactionConsumptionOverlay, attrs)
      |> respond(conn, true)
    else
      error ->
        respond(error, conn, true)
    end
  end

  def consume(conn, _) do
    handle_error(conn, :invalid_parameter)
  end

  def approve(conn, attrs), do: confirm(conn, conn.assigns, attrs, true)
  def reject(conn, attrs), do: confirm(conn, conn.assigns, attrs, false)

  defp confirm(conn, confirmer, %{"id" => id} = attrs, approved) do
    id
    |> TransactionConsumptionConfirmerGate.confirm(
      approved,
      confirmer,
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

  # Respond with a list of transaction consumptions
  defp respond_multiple(%Paginator{} = paged_transaction_consumptions, conn) do
    render(conn, :transaction_consumptions, %{
      transaction_consumptions: paged_transaction_consumptions
    })
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond({:error, error}, conn, _dispatch?) when is_atom(error) do
    handle_error(conn, error)
  end

  defp respond({:error, code, description}, conn, _dispatch?) do
    handle_error(conn, code, description)
  end

  defp respond({:error, changeset}, conn, _dispatch?) do
    handle_error(conn, :invalid_parameter, changeset)
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
    render(conn, :transaction_consumption, %{
      transaction_consumption: consumption
    })
  end

  defp dispatch_confirm_event(consumption) do
    if TransactionConsumption.finalized?(consumption) do
      Event.dispatch(:transaction_consumption_finalized, %{consumption: consumption})
    end
  end

  @spec permit(
          :all | :create | :get | :update,
          map(),
          String.t()
          | %Account{}
          | %TransactionRequest{}
          | %TransactionConsumption{}
          | %User{}
          | %Wallet{}
          | nil
        ) :: :ok | {:error, any()} | no_return()
  defp permit(action, params, data) do
    Bodyguard.permit(TransactionConsumptionPolicy, action, params, data)
  end
end
