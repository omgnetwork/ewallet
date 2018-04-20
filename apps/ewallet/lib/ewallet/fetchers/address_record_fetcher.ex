defmodule EWallet.AddressRecordFetcher do
  @moduledoc """
  Handles the logic for fetching the minted token and the from and to balances.
  """
  alias EWalletDB.{MintedToken, Balance}

  def fetch(%{
    "from_address" => from_address,
    "to_address" => to_address,
    "token_id" => token_id
  }) do
    from_balance = Balance.get(from_address)
    to_balance = Balance.get(to_address)
    minted_token = MintedToken.get(token_id)

    handle_result(from_balance, to_balance, minted_token)
  end

  defp handle_result(nil, _, _), do: {:error, :from_address_not_found}
  defp handle_result(_, nil, _), do: {:error, :to_address_not_found}
  defp handle_result(_, _, nil), do: {:error, :minted_token_not_found}
  defp handle_result(from_balance, to_balance, minted_token) do
    {:ok, from_balance, to_balance, minted_token}
  end
end
