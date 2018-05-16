defmodule EWallet.TransactionConsumptionValidator do
  @moduledoc """
  Handles all validations for a transaction request, including amount and
  expiration.
  """
  alias EWallet.Web.V1.Event
  alias EWalletDB.{Repo, TransactionConsumption, MintedToken}

  def validate_max_consumptions_per_user(request, balance) do
    validate_max_consumptions_per_user(
      max: request.max_consumptions_per_user,
      is_user_request: !is_nil(balance.user_uuid) && is_nil(balance.account_uuid),
      request_uuid: request.uuid,
      balance: balance
    )
  end

  def validate_max_consumptions_per_user(
        max: nil,
        is_user_request: _,
        request_uuid: _,
        balance: balance
      ) do
    {:ok, balance}
  end

  def validate_max_consumptions_per_user(
        max: _,
        is_user_request: false,
        request_uuid: _,
        balance: balance
      ) do
    {:ok, balance}
  end

  def validate_max_consumptions_per_user(
        max: max,
        is_user_request: true,
        request_uuid: request_uuid,
        balance: balance
      ) do
    current_consumptions =
      TransactionConsumption.all_active_for_user(balance.user_uuid, request_uuid)

    case length(current_consumptions) < max do
      true -> {:ok, balance}
      false -> {:error, :max_consumptions_per_user_reached}
    end
  end

  def get_and_validate_minted_token(request, nil) do
    request = request |> Repo.preload(:minted_token)
    {:ok, request.minted_token}
  end

  def get_and_validate_minted_token(request, token_id) do
    case MintedToken.get(token_id) do
      nil -> {:error, :minted_token_not_found}
      minted_token -> validate_minted_token(request, minted_token)
    end
  end

  def validate_minted_token(request, minted_token) do
    case request.minted_token_uuid == minted_token.uuid do
      true -> {:ok, minted_token}
      false -> {:error, :invalid_minted_token_provided}
    end
  end

  def validate_consumption(consumption) do
    {:ok, consumption} = TransactionConsumption.expire_if_past_expiration_date(consumption)

    case TransactionConsumption.expired?(consumption) do
      false ->
        {:ok, consumption}

      true ->
        Event.dispatch(:transaction_consumption_finalized, %{consumption: consumption})
        {:error, :expired_transaction_consumption}
    end
  end
end
