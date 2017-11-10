defmodule Kubera.Balance do
  @moduledoc """
  Handles the retrieval and formatting of balances from the local ledger.
  """
  alias KuberaDB.{User, MintedToken}
  alias KuberaMQ.Balance

  @doc """
  Prepare the list of balances and turn them into a suitable format for
  KuberaAPI using a provider_user_id.

  ## Examples

    res = Balance.all(%{"provider_user_id" => "123"})

    case res do
      {:ok, balances} ->
        # Everything went well, do something.
        # response is the response returned by the local ledger (Caishen for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (Caishen maybe) and the
        # retrieval failed.
    end

  """
  def all(%{"provider_user_id" => provider_user_id}) do
    user = User.get_by_provider_user_id(provider_user_id)

    case user do
      nil ->
        {:error, :provider_user_id_not_found}
      user ->
        balance = User.get_main_balance(user)
        format(balance.address)
    end
  end

  @doc """
  Prepare the list of balances and turn them into a suitable format for
  KuberaAPI using only an address.

  ## Examples

    res = Balance.all(%{"address" => "d26fc18f-d403-4a39-a039-21e2bc713688"})

    case res do
      {:ok, balances} ->
        # Everything went well, do something.
        # response is the response returned by the local ledger (Caishen for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (Caishen maybe) and the
        # retrieval failed.
    end

  """
  def all(%{"address" => address}) do
    format(address)
  end

  @doc """
  Prepare the list of balances (actually only 1 element) and turn them into a
  suitable format for KuberaAPI using address and symbol

  ## Examples

    res = Balance.get("OMG", "d26fc18f-d403-4a39-a039-21e2bc713688"})

    case res do
      {:ok, balances} ->
        # Everything went well, do something.
        # response is the response returned by the local ledger (Caishen for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (Caishen maybe) and the
        # retrieval failed.
    end

  """
  def get(%User{} = user, %MintedToken{} = minted_token) do
    user_balance = User.get_main_balance(user)
    get(minted_token.symbol, user_balance.address)
  end

  def get(symbol, address) do
    symbol |> Balance.get(address) |> process_response(address)
  end

  defp format(address) do
    address |> Balance.all() |> process_response(address)
  end

  defp process_response(response, address) do
    case response do
      {:ok, data} ->
        balances =
          data["amounts"]
          |> Map.keys()
          |> MintedToken.get_all()
          |> map_minted_tokens(data["amounts"])

        # For now Caishen returns a single address but we're preparing for an
        # array to be returned
        {:ok, [%{address: address, balances: balances}]}
      response ->
        response
    end
  end

  defp map_minted_tokens(minted_tokens, amounts) do
    Enum.map(minted_tokens, fn minted_token ->
      %{
        minted_token: minted_token,
        amount: amounts[minted_token.symbol]
      }
    end)
  end
end
