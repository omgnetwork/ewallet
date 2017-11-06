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

  defp format(address) do
    response = Balance.all(address)

    case response do
      {:ok, data} ->
        balances =
          data["amounts"]
          |> Map.keys()
          |> MintedToken.get_all()
          |> map_minted_tokens(address, data["amounts"])

        {:ok, balances}
      response ->
        response
    end
  end

  defp map_minted_tokens(minted_tokens, address, amounts) do
    Enum.map(minted_tokens, fn minted_token ->
      %{
        minted_token: minted_token,
        amount: amounts[minted_token.symbol],
        address: address
      }
    end)
  end
end
