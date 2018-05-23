defmodule EWallet.AddressRecordFetcher do
  @moduledoc """
  Handles the logic for fetching the token and the from and to wallets.
  """
  alias EWalletDB.{Token, Wallet}

  def fetch(%{
        "from_address" => from_address,
        "to_address" => to_address,
        "token_id" => token_id
      }) do
    from_wallet = Wallet.get(from_address)
    to_wallet = Wallet.get(to_address)
    token = Token.get(token_id)

    handle_result(from_wallet, to_wallet, token)
  end

  defp handle_result(nil, _, _), do: {:error, :from_address_not_found}
  defp handle_result(_, nil, _), do: {:error, :to_address_not_found}
  defp handle_result(_, _, nil), do: {:error, :token_not_found}

  defp handle_result(from_wallet, to_wallet, token) do
    {:ok, from_wallet, to_wallet, token}
  end
end
