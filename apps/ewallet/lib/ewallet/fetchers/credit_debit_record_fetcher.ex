defmodule EWallet.CreditDebitRecordFetcher do
  @moduledoc """
  Handles the logic for fetching the user and token.
  """
  alias EWalletDB.{User, Token, Account}

  def fetch(
        %{
          "provider_user_id" => provider_user_id,
          "token_id" => token_id
        } = attrs
      ) do
    user = User.get_by_provider_user_id(provider_user_id)
    token = Token.get(token_id)
    account = load_account(attrs["account_id"], attrs["account_address"])
    handle_result(account, user, token, attrs["account_id"])
  end

  defp load_account(nil, nil), do: Account.get_master_account(preload: :wallets)

  defp load_account(nil, _address), do: nil

  defp load_account(account_id, _address), do: Account.get(account_id, preload: :wallets)

  defp handle_result(_, _, nil, _), do: {:error, :token_not_found}
  defp handle_result(_, nil, _, _), do: {:error, :provider_user_id_not_found}

  # master / account = nil and account_id is nil
  defp handle_result(account, user, token, nil), do: {:ok, account, user, token}

  # has account id but account was not found
  defp handle_result(nil, _, _, _account_id), do: {:error, :account_id_not_found}

  defp handle_result(account, user, token, _account_id), do: {:ok, account, user, token}
end
