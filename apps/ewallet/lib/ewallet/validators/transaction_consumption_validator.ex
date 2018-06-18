defmodule EWallet.TransactionConsumptionValidator do
  @moduledoc """
  Handles all validations for a transaction request, including amount and
  expiration.
  """
  alias EWallet.Web.V1.Event
  alias EWalletDB.{Repo, TransactionRequest, TransactionConsumption, Token}

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
  def validate_before_confirmation(consumption, owner) do
    with {request, wallet} <- {consumption.transaction_request, consumption.wallet},
         true <-
           TransactionRequest.is_owned_by?(request, owner) || :not_transaction_request_owner,
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
  def validate_amount(request, amount) do
    case request.allow_amount_override do
      true ->
        {:ok, amount || request.amount}

      false ->
        case amount do
          nil -> {:ok, request, request.amount}
          _amount -> {:error, :unauthorized_amount_override}
        end
    end
  end

  @spec get_and_validate_token(TransactionRequest.t(), UUID.t()) ::
          {:ok, Token.t()}
          | {:error, Atom.t()}
  def get_and_validate_token(request, token_id) do
    with request <- Repo.preload(request, :token),
         true <- !is_nil(token_id) || {:ok, request.token},
         %Token{} = token <- Token.get(token_id) || :token_not_found,
         true <- request.token_uuid == token.uuid || :invalid_token_provided do
      {:ok, token}
    else
      error when is_atom(error) ->
        {:error, error}

      res ->
        res
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
end
