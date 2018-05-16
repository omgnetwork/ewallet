defmodule EWallet.TransactionRequestValidator do
  @moduledoc """
  Handles all validations for a transaction request, including amount and
  expiration.
  """
  alias EWalletDB.{
    Account,
    User,
    TransactionRequest
  }

  @spec validate_amount(TransactionRequest.t(), Integer.t()) ::
          {:ok, TransactionRequest.t()} | {:error, :unauthorized_amount_override}
  def validate_amount(request, amount) do
    case request.allow_amount_override do
      true ->
        {:ok, amount || request.amount}

      false ->
        case amount do
          nil -> {:ok, request.amount}
          _amount -> {:error, :unauthorized_amount_override}
        end
    end
  end

  @spec validate_request(TransactionRequest.t()) ::
          {:ok, TransactionRequest.t()}
          | {:error, Atom.t()}
  def validate_request(request) do
    {:ok, request} = TransactionRequest.expire_if_past_expiration_date(request)

    case TransactionRequest.valid?(request) do
      true -> {:ok, request}
      false -> {:error, String.to_existing_atom(request.expiration_reason)}
    end
  end

  def is_owner?(request, %Account{} = account) do
    request.account_uuid == account.uuid
  end

  def is_owner?(request, %User{} = user) do
    request.user_uuid == user.uuid
  end

  @spec expiration_from_lifetime(TransactionRequest.t()) :: NaiveDateTime.t() | nil
  def expiration_from_lifetime(request) do
    TransactionRequest.expiration_from_lifetime(request)
  end

  @spec expire_if_past_expiration_date(TransactionRequest.t()) ::
          {:ok, TransactionRequest.t()}
          | {:error, Atom.t()}
          | {:error, Map.t()}
  def expire_if_past_expiration_date(request) do
    res = TransactionRequest.expire_if_past_expiration_date(request)

    case res do
      {:ok, %TransactionRequest{status: "expired"} = request} ->
        {:error, String.to_existing_atom(request.expiration_reason)}

      {:ok, request} ->
        {:ok, request}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec expire_if_max_consumption(TransactionRequest.t()) ::
          {:ok, TransactionRequest.t()}
          | {:error, Map.t()}
  def expire_if_max_consumption(request) do
    TransactionRequest.expire_if_max_consumption(request)
  end
end
