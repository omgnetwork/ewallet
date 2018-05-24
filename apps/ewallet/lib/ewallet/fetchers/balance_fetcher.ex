defmodule EWallet.BalanceFetcher do
  @moduledoc """
  Handles the retrieval and formatting of balances from the local ledger.
  """
  alias EWalletDB.{User, Token}
  alias LocalLedger.Wallet

  @doc """
  Prepare the list of balances and turn them into a suitable format for
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
        format_all(wallet)
    end
  end

  @doc """
  Prepare the list of balances and turn them into a suitable format for
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
    address |> EWalletDB.Wallet.get() |> format_all()
  end

  @doc """
  Prepare the list of balances and turn them into a
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
  def get(%User{} = user, %Token{} = token) do
    user_wallet = User.get_primary_wallet(user)
    get(token.id, user_wallet)
  end

  @doc """
  Prepare the list of balances and turn them into a
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
  def get(id, wallet) do
    id |> Wallet.get_balance(wallet.address) |> process_response(wallet, :one)
  end

  defp format_all(wallet) do
    wallet.address |> Wallet.all_balances() |> process_response(wallet, :all)
  end

  defp process_response({:ok, data}, wallet, type) do
    balances =
      type
      |> load_tokens(data)
      |> map_tokens(data)

    {:ok, Map.put(wallet, :balances, balances)}
  end

  defp load_tokens(:all, _), do: Token.all()

  defp load_tokens(:one, amounts) do
    amounts |> Map.keys() |> Token.get_all()
  end

  defp map_tokens(tokens, amounts) do
    Enum.map(tokens, fn token ->
      %{
        token: token,
        amount: amounts[token.id] || 0
      }
    end)
  end
end
