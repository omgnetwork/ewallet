defmodule AdminAPI.V1.TransactionConsumptionController do
  use AdminAPI, :controller
  alias EWallet.Web.Embedder
  @behaviour EWallet.Web.Embedder
  import AdminAPI.V1.ErrorHandler
  alias EWallet.Web.{SearchParser, SortParser, Paginator, Preloader}

  alias EWallet.{
    Web.V1.Event,
    TransactionConsumptionConsumerGate,
    TransactionConsumptionConfirmerGate,
    TransactionConsumptionFetcher
  }

  alias EWalletDB.{Account, User, TransactionRequest, TransactionConsumption, Wallet}

  # The fields that are allowed to be embedded.
  # These fields must be one of the schema's association names.
  def embeddable, do: [:account, :token, :transaction, :transaction_request, :user]

  # The fields returned by `embeddable/0` are embedded regardless of the request.
  # These fields must be one of the schema's association names.
  def always_embed, do: [:token]

  @mapped_fields %{"created_at" => "inserted_at"}
  @preload_fields [:account, :user, :wallet, :token, :transaction_request, :transfer]
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

  def all_for_account(conn, %{"account_id" => account_id} = attrs) do
    with %Account{} = account <- Account.get(account_id) || {:error, :account_id_not_found} do
      :account_uuid
      |> TransactionConsumption.query_all_for(account.uuid)
      |> SearchParser.search_with_terms(attrs, @search_fields)
      |> do_all(conn, attrs)
    else
      error -> respond(error, conn)
    end
  end

  def all_for_account(conn, %{}) do
    handle_error(conn, :invalid_parameter, "Parameter 'account_id' is required.")
  end

  def all_for_user(conn, %{"user_id" => user_id} = attrs) do
    with %User{} = user <- User.get(user_id) || {:error, :user_id_not_found} do
      :user_uuid
      |> TransactionConsumption.query_all_for(user.uuid)
      |> SearchParser.search_with_terms(attrs, @search_fields)
      |> do_all(conn, attrs)
    else
      error -> respond(error, conn)
    end
  end

  def all_for_user(conn, %{}) do
    handle_error(conn, :invalid_parameter, "Parameter 'user_id' is required.")
  end

  def all_for_transaction_request(
        conn,
        %{"transaction_request_id" => transaction_request_id} = attrs
      ) do
    with %TransactionRequest{} = transaction_request <-
           TransactionRequest.get(transaction_request_id) ||
             {:error, :transaction_request_not_found} do
      :transaction_request_uuid
      |> TransactionConsumption.query_all_for(transaction_request.uuid)
      |> SearchParser.search_with_terms(attrs, @search_fields)
      |> do_all(conn, attrs)
    else
      error -> respond(error, conn)
    end
  end

  def all_for_transaction_request(conn, %{}) do
    handle_error(conn, :invalid_parameter, "Parameter 'transaction_request_id' is required.")
  end

  def all_for_wallet(conn, %{"address" => address} = attrs) do
    with %Wallet{} = wallet <- Wallet.get(address) || {:error, :wallet_not_found} do
      :wallet_address
      |> TransactionConsumption.query_all_for(wallet.address)
      |> SearchParser.search_with_terms(attrs, @search_fields)
      |> do_all(conn, attrs)
    else
      error -> respond(error, conn)
    end
  end

  def all_for_wallet(conn, %{}) do
    handle_error(conn, :invalid_parameter, "Parameter 'address' is required.")
  end

  def all(conn, attrs) do
    TransactionConsumption
    |> SearchParser.to_query(attrs, @search_fields)
    |> do_all(conn, attrs)
  end

  def get(conn, %{"id" => id}) do
    id
    |> TransactionConsumptionFetcher.get()
    |> respond(conn)
  end

  def consume(conn, %{"idempotency_token" => idempotency_token} = attrs)
      when idempotency_token != nil do
    attrs
    |> TransactionConsumptionConsumerGate.consume()
    |> respond(conn)
  end

  def consume(conn, _) do
    handle_error(conn, :invalid_parameter)
  end

  def approve(conn, attrs), do: confirm(conn, get_actor(conn.assigns), attrs, true)
  def reject(conn, attrs), do: confirm(conn, get_actor(conn.assigns), attrs, false)

  def do_all(query, conn, attrs) do
    query
    |> Preloader.to_query(@preload_fields)
    |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
    |> Paginator.paginate_attrs(attrs)
    |> respond_multiple(conn)
  end

  defp get_actor(%{admin_user: _admin_user}) do
    # To do -> change this to actually check if the user has admin rights over the
    # owner of the consumption
    Account.get_master_account()
  end

  defp get_actor(%{key: key}) do
    key.account
  end

  defp confirm(conn, entity, %{"id" => id}, approved) do
    id
    |> TransactionConsumptionConfirmerGate.confirm(approved, entity)
    |> respond(conn)
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

  defp respond({:error, error}, conn) when is_atom(error), do: handle_error(conn, error)

  defp respond({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp respond({:error, consumption, code, description}, conn) do
    dispatch_confirm_event(consumption)
    handle_error(conn, code, description)
  end

  defp respond({:ok, consumption}, conn) do
    dispatch_confirm_event(consumption)

    render(conn, :transaction_consumption, %{
      transaction_consumption: Embedder.embed(__MODULE__, consumption, conn.body_params["embed"])
    })
  end

  defp dispatch_confirm_event(consumption) do
    if TransactionConsumption.finalized?(consumption) do
      Event.dispatch(:transaction_consumption_finalized, %{consumption: consumption})
    end
  end
end
