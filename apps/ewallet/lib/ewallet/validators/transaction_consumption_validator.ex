defmodule EWallet.TransactionConsumptionValidator do
  @moduledoc """
  Handles all validations for a transaction request, including amount and
  expiration.
  """
  alias EWallet.{Helper, TransactionConsumptionPolicy}
  alias EWallet.Web.V1.Event
  alias EWalletDB.{Repo, TransactionRequest, TransactionConsumption, Token, ExchangePair}

  @spec validate_before_consumption(TransactionRequest.t(), any(), nil | keyword() | map()) ::
          {:ok, TransactionRequest.t(), Token.t(), integer()}
          | {:error, Atom.t()}
  def validate_before_consumption(request, wallet, attrs) do
    with amount <- attrs["amount"],
         token_id <- attrs["token_id"],
         {:ok, request} <- TransactionRequest.expire_if_past_expiration_date(request),
         true <- TransactionRequest.valid?(request) || request.expiration_reason,
         {:ok, amount} <- validate_amount(request, amount),
         {:ok, _wallet} <- validate_max_consumptions_per_user(request, wallet),
         {:ok, token} <- get_and_validate_token(request, token_id) do
      {:ok, request, token, amount}
    else
      error when is_binary(error) ->
        {:error, String.to_existing_atom(error)}

      error when is_atom(error) ->
        {:error, error}

      error ->
        error
    end
  end

  @spec validate_before_confirmation(TransactionConsumption.t(), Account.t() | User.t()) ::
          {:ok, TransactionConsumption.t()}
          | {:error, Atom.t()}
  def validate_before_confirmation(consumption, confirmer) do
    with {request, wallet} <- {consumption.transaction_request, consumption.wallet},
         request <- Repo.preload(request, [:wallet]),
         :ok <- Bodyguard.permit(TransactionConsumptionPolicy, :confirm, confirmer, request),
         {:ok, request} <- TransactionRequest.expire_if_past_expiration_date(request),
         {:ok, _wallet} <- validate_max_consumptions_per_user(request, wallet),
         true <- TransactionRequest.valid?(request) || request.expiration_reason,
         {:ok, consumption} = TransactionConsumption.expire_if_past_expiration_date(consumption) do
      case TransactionConsumption.expired?(consumption) do
        false ->
          {:ok, consumption}

        true ->
          Event.dispatch(:transaction_consumption_finalized, %{consumption: consumption})
          {:error, :expired_transaction_consumption}
      end
    else
      error when is_binary(error) ->
        {:error, String.to_existing_atom(error)}

      error when is_atom(error) ->
        {:error, error}

      error ->
        error
    end
  end

  @spec validate_amount(TransactionRequest.t(), Integer.t()) ::
          {:ok, TransactionRequest.t()} | {:error, :unauthorized_amount_override}
  def validate_amount(%TransactionRequest{amount: nil} = _request, nil) do
    {:error, :invalid_parameter, "'amount' is required for transaction consumption."}
  end

  def validate_amount(%TransactionRequest{amount: _amount} = _request, nil) do
    {:ok, nil}
  end

  def validate_amount(%TransactionRequest{allow_amount_override: true} = _request, amount)
      when is_binary(amount) do
    case Helper.string_to_integer(amount) do
      {:ok, amount} ->
        {:ok, amount}

      error ->
        error
    end
  end

  def validate_amount(%TransactionRequest{allow_amount_override: true} = _request, amount) do
    {:ok, amount}
  end

  def validate_amount(%TransactionRequest{allow_amount_override: false} = _request, amount)
      when not is_nil(amount) do
    {:error, :unauthorized_amount_override}
  end

  @spec get_and_validate_token(TransactionRequest.t(), String.t()) ::
          {:ok, Token.t()}
          | {:error, Atom.t()}
  def get_and_validate_token(%TransactionRequest{token_uuid: nil} = _request, nil) do
    {:error, :invalid_parameter,
     "'token_id' is required since the transaction request does not specify any."}
  end

  def get_and_validate_token(%TransactionRequest{token_uuid: _token_uuid} = request, nil) do
    {:ok, Repo.preload(request, :token).token}
  end

  def get_and_validate_token(%{token_uuid: nil} = _request, token_id) do
    case Token.get(token_id) do
      nil ->
        {:error, :token_not_found}

      token ->
        {:ok, token}
    end
  end

  def get_and_validate_token(request, token_id) do
    with %Token{} = token <- Token.get(token_id) || {:error, :token_not_found},
         request_token <- Repo.preload(request, :token).token,
         {:ok, _pair} <- fetch_pair(request.type, request_token.uuid, token.uuid) do
      {:ok, token}
    else
      error -> error
    end
  end

  def validate_max_consumptions_per_user(request, wallet) do
    with max <- request.max_consumptions_per_user,
         # max has a value
         false <- is_nil(max),
         # The consumption is for a user
         false <- is_nil(wallet.user_uuid),
         current_consumptions <-
           TransactionConsumption.all_active_for_user(wallet.user_uuid, request.uuid),
         false <- length(current_consumptions) < max do
      {:error, :max_consumptions_per_user_reached}
    else
      _ -> {:ok, wallet}
    end
  end

  defp fetch_pair(_type, request_token_uuid, consumption_token_uuid)
       when request_token_uuid == consumption_token_uuid do
    {:ok, nil}
  end

  defp fetch_pair(type, request_token_uuid, consumption_token_uuid) do
    case type do
      "send" ->
        ExchangePair.fetch_exchangable_pair(
          %{uuid: request_token_uuid},
          %{uuid: consumption_token_uuid}
        )

      "receive" ->
        ExchangePair.fetch_exchangable_pair(
          %{uuid: consumption_token_uuid},
          %{uuid: request_token_uuid}
        )
    end
  end
end
