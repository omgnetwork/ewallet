defmodule AdminAPI.V1.TransactionConsumptionController do
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  @behaviour EWallet.Web.Embedder
  alias AdminAPI.V1.AccountHelper
  alias EWallet.Web.Embedder
  alias EWallet.TransactionConsumptionPolicy
  alias EWallet.Web.{SearchParser, SortParser, Paginator, Preloader}

  alias EWallet.{
    Web.V1.Event,
    TransactionConsumptionConsumerGate,
    TransactionConsumptionConfirmerGate,
    TransactionConsumptionFetcher,
    UserFetcher
  }

  alias EWalletDB.{Account, User, TransactionRequest, TransactionConsumption, Wallet}

  # The fields that are allowed to be embedded.
  # These fields must be one of the schema's association names.
  def embeddable, do: [:account, :token, :transaction, :transaction_request, :user]

  # The fields returned by `embeddable/0` are embedded regardless of the request.
  # These fields must be one of the schema's association names.
  def always_embed, do: [:token]

  @mapped_fields %{"created_at" => "inserted_at"}
  @preload_fields [:account, :user, :wallet, :token, :transaction_request, :transaction]
  @search_fields [:id, :status, :correlation_id, :idempotency_token]
  @sort_fields [
    :id,
    :status,
    :correlation_id,
    :idempotency_token,
    :inserted_at,
    :updated_at,
    :approved_at,
    :rejected_at,
    :confirmed_at,
    :failed_at,
    :expired_at
  ]

  def all_for_account(conn, %{"id" => account_id, "owned" => true} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account),
         linked_user_uuids <-
           [account.uuid] |> Account.get_all_users() |> Enum.map(fn user -> user.uuid end) do
      [account.uuid]
      |> TransactionConsumption.query_all_for_account_and_user_uuids(linked_user_uuids)
      |> do_all(attrs, conn)
    else
      error -> respond(error, conn, false)
    end
  end

  def all_for_account(conn, %{"id" => account_id} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account),
         descendant_uuids <- Account.get_all_descendants_uuids(account),
         linked_user_uuids <-
           descendant_uuids |> Account.get_all_users() |> Enum.map(fn user -> user.uuid end) do
      descendant_uuids
      |> TransactionConsumption.query_all_for_account_and_user_uuids(linked_user_uuids)
      |> do_all(attrs, conn)
    else
      error -> respond(error, conn, false)
    end
  end

  def all_for_account(conn, _) do
    handle_error(conn, :invalid_parameter, "Parameter 'id' is required.")
  end

  def all_for_user(conn, attrs) do
    with {:ok, %User{} = user} <- UserFetcher.fetch(attrs) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, user) do
      :user_uuid
      |> TransactionConsumption.query_all_for(user.uuid)
      |> do_all(attrs, conn)
    else
      {:error, :invalid_parameter} ->
        handle_error(
          conn,
          :invalid_parameter,
          "Parameter 'user_id' or 'provider_user_id' is required."
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
      "Parameter 'formatted_transaction_request_id' is required."
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
    handle_error(conn, :invalid_parameter, "Parameter 'address' is required.")
  end

  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns, nil),
         account_uuids <- AccountHelper.get_accessible_account_uuids(conn.assigns),
         descendant_uuids <- Account.get_all_descendants_uuids(account_uuids),
         linked_user_uuids <-
           descendant_uuids |> Account.get_all_users() |> Enum.map(fn user -> user.uuid end) do
      descendant_uuids
      |> TransactionConsumption.query_all_for_account_and_user_uuids(linked_user_uuids)
      |> do_all(attrs, conn)
    else
      error -> respond(error, conn, false)
    end
  end

  defp do_all(query, attrs, conn) do
    query
    |> Preloader.to_query(@preload_fields)
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
    |> Paginator.paginate_attrs(attrs)
    |> respond_multiple(conn)
  end

  def get(conn, %{"id" => id}) do
    with %TransactionConsumption{} = consumption <-
           TransactionConsumptionFetcher.get(id) || {:error, :unauthorized},
         :ok <- permit(:get, conn.assigns, consumption) do
      render(conn, :transaction_consumption, %{
        transaction_consumption:
          Embedder.embed(__MODULE__, consumption, conn.body_params["embed"])
      })
    else
      error -> respond(error, conn, false)
    end
  end

  def consume(conn, %{"idempotency_token" => idempotency_token} = attrs)
      when idempotency_token != nil do
    attrs
    |> TransactionConsumptionConsumerGate.consume()
    |> respond(conn, true)
  end

  def consume(conn, _) do
    handle_error(conn, :invalid_parameter)
  end

  def approve(conn, attrs), do: confirm(conn, conn.assigns, attrs, true)
  def reject(conn, attrs), do: confirm(conn, conn.assigns, attrs, false)

  defp confirm(conn, confirmer, %{"id" => id}, approved) do
    case TransactionConsumptionConfirmerGate.confirm(id, approved, confirmer) do
      {:ok, consumption} ->
        respond({:ok, consumption}, conn, true)

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

  defp respond({:error, %TransactionConsumption{} = consumption, code}, conn, true) do
    dispatch_confirm_event(consumption)
    handle_error(conn, code)
  end

  defp respond({:error, %TransactionConsumption{} = _consumption, code}, conn, false) do
    handle_error(conn, code)
  end

  defp respond({:error, code, description}, conn, _dispatch?),
    do: handle_error(conn, code, description)

  defp respond({:error, error}, conn, _dispatch?) when is_atom(error),
    do: handle_error(conn, error)

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
      transaction_consumption: Embedder.embed(__MODULE__, consumption, conn.body_params["embed"])
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
