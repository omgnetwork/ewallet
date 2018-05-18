defmodule EWallet.BalanceFetcher do
  @moduledoc """
  Handles the retrieval and formatting of wallets from the local ledger.
  """
  alias EWalletDB.{User, MintedToken}
  alias LocalLedger.Wallet

  @doc """
  Prepare the list of wallets and turn them into a suitable format for
  EWalletAPI using a provider_user_id.

  ## Examples

    res = BalanceFetcher.all(%{"provider_user_id" => "123"})

    case res do
      {:ok, wallets} ->
        # Everything went well, do something.
        # response is the response returned by the ledger (LocalLedger for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (LocalLedger maybe) and the
        # retrieval failed.
    end

  """
  def all(%{"provider_user_id" => provider_user_id}) do
    user = User.get_by_provider_user_id(provider_user_id)

    case user do
      nil ->
        {:error, :provider_user_id_not_found}

      user ->
        wallet = User.get_primary_wallet(user)
        format_all(wallet.address)
    end
  end

  @doc """
  Prepare the list of wallets and turn them into a suitable format for
  EWalletAPI using only an address.

  ## Examples

    res = BalanceFetcher.all(%{"address" => "d26fc18f-d403-4a39-a039-21e2bc713688"})

    case res do
      {:ok, wallets} ->
        # Everything went well, do something.
        # response is the response returned by the local ledger (LocalLedger for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (LocalLedger maybe) and the
        # retrieval failed.
    end

  """
  def all(%{"address" => address}) do
    format_all(address)
  end

  @doc """
  Prepare the list of wallets and turn them into a
  suitable format for EWalletAPI using a user and a token_id

  ## Examples

    res = Wallet.get_balance(user, "tok_OMG_01cbennsd8q4xddqfmewpwzxdy")

    case res do
      {:ok, wallets} ->
        # Everything went well, do something.
        # response is the response returned by the local ledger (LocalLedger for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (LocalLedger maybe) and the
        # retrieval failed.
    end

  """
  def get(%User{} = user, %MintedToken{} = minted_token) do
    user_wallet = User.get_primary_wallet(user)
    get(minted_token.id, user_wallet.address)
  end

  @doc """
  Prepare the list of wallets and turn them into a
  suitable format for EWalletAPI using a token_id and an address

  ## Examples

    res = Wallet.get_balance("tok_OMG_01cbennsd8q4xddqfmewpwzxdy", "22a83591-d684-4bfd-9310-6bdecdec4f81")

    case res do
      {:ok, wallets} ->
        # Everything went well, do something.
        # response is the response returned by the local ledger (LocalLedger for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (LocalLedger maybe) and the
        # retrieval failed.
    end

  """
  def get(id, address) do
    id |> Wallet.get_balance(address) |> process_response(address, :one)
  end

  defp format_all(address) do
    address |> Wallet.all_balances() |> process_response(address, :all)
  end

  defp process_response(wallets, address, type) do
    case wallets do
      {:ok, data} ->
        balances =
          type
          |> load_minted_tokens(data)
          |> map_minted_tokens(data)

        {:ok, %{address: address, balances: balances}}

      wallets ->
        wallets
    end
  end

  defp load_minted_tokens(:all, _), do: MintedToken.all()

  defp load_minted_tokens(:one, amounts) do
    amounts |> Map.keys() |> MintedToken.get_all()
  end

  defp map_minted_tokens(minted_tokens, amounts) do
    Enum.map(minted_tokens, fn minted_token ->
      %{
        minted_token: minted_token,
        amount: amounts[minted_token.id] || 0
      }
    end)
  end
end
