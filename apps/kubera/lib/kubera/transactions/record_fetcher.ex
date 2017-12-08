defmodule Kubera.Transactions.RecordFetcher do
  @moduledoc """
  Handles the logic for fetching the user and minted_token.
  """
  alias KuberaDB.{User, MintedToken, Account}

  def fetch(%{
    "provider_user_id" => provider_user_id,
    "token_id" => token_friendly_id
  } = attrs) do
    user = User.get_by_provider_user_id(provider_user_id)
    minted_token = MintedToken.get(token_friendly_id)
    account = load_account(attrs["account_id"], minted_token)
    handle_result(account, user, minted_token)
  end

  defp load_account(nil, nil), do: nil
  defp load_account(nil, minted_token), do: Account.get(minted_token.account_id, %{preload: true})
  defp load_account(account_id, _minted_token), do: Account.get(account_id, %{preload: true})

  defp handle_result(nil, _, _), do: {:error, :account_id_not_found}
  defp handle_result(_, nil, _), do: {:error, :provider_user_id_not_found}
  defp handle_result(_, _, nil), do: {:error, :minted_token_not_found}
  defp handle_result(account, user, minted_token), do: {:ok, account, user, minted_token}
end
