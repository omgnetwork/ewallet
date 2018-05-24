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
    account = load_account(attrs["account_id"])
    handle_result(account, user, token)
  end

  defp load_account(nil), do: Account.get_master_account(preload: :wallets)

  defp load_account(account_id), do: Account.get(account_id, preload: :wallets)

  defp handle_result(_, _, nil), do: {:error, :token_not_found}
  defp handle_result(nil, _, _), do: {:error, :account_id_not_found}
  defp handle_result(_, nil, _), do: {:error, :provider_user_id_not_found}
  defp handle_result(account, user, token), do: {:ok, account, user, token}
end
