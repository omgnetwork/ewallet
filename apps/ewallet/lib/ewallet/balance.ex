defmodule EWallet.Balance do
  @moduledoc """
  Handles the retrieval and formatting of balances from the local ledger.
  """
  alias EWalletDB.{User, MintedToken}
  alias EWalletMQ.Publishers.Balance

  @doc """
  Prepare the list of balances and turn them into a suitable format for
  EWalletAPI using a provider_user_id.

  ## Examples

    res = Balance.all(%{"provider_user_id" => "123"})

    case res do
      {:ok, balances} ->
        # Everything went well, do something.
        # response is the response returned by the local ledger (LocalLedger for
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
        balance = User.get_primary_balance(user)
        format_all(balance.address)
    end
  end

  @doc """
  Prepare the list of balances and turn them into a suitable format for
  EWalletAPI using only an address.

  ## Examples

    res = Balance.all(%{"address" => "d26fc18f-d403-4a39-a039-21e2bc713688"})

    case res do
      {:ok, balances} ->
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
  Prepare the list of balances and turn them into a
  suitable format for EWalletAPI using a user and a token_friendly_id

  ## Examples

    res = Balance.get(user, "OMG:e4222f72-46c5-4baa-98c0-680908fcdd84")

    case res do
      {:ok, balances} ->
        # Everything went well, do something.
        # response is the response returned by the local ledger (LocalLedger for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (LocalLedger maybe) and the
        # retrieval failed.
    end

  """
  def get(%User{} = user, %MintedToken{} = minted_token) do
    user_balance = User.get_primary_balance(user)
    get(minted_token.friendly_id, user_balance.address)
  end

  @doc """
  Prepare the list of balances and turn them into a
  suitable format for EWalletAPI using a token_friendly_id and an address

  ## Examples

    res = Balance.get("OMG:e4222f72-46c5-4baa-98c0-680908fcdd84", "22a83591-d684-4bfd-9310-6bdecdec4f81")

    case res do
      {:ok, balances} ->
        # Everything went well, do something.
        # response is the response returned by the local ledger (LocalLedger for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (LocalLedger maybe) and the
        # retrieval failed.
    end

  """
  def get(friendly_id, address) do
    friendly_id |> Balance.get(address) |> process_response(address, :one)
  end

  defp format_all(address) do
    address |> Balance.all() |> process_response(address, :all)
  end

  defp process_response(response, address, type) do
    case response do
      {:ok, data} ->
        balances =
        type
        |> load_minted_tokens(data["amounts"])
        |> map_minted_tokens(data["amounts"])

        {:ok, %{address: address, balances: balances}}
      response ->
        response
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
        amount: amounts[minted_token.friendly_id] || 0
      }
    end)
  end
end
