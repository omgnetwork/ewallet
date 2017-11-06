defmodule Kubera.Mint do
  @moduledoc """
  Handles the mint creation logic. Since it relies on external applications to
  handle the transactions (i.e. Caishen), a callback needs to be passed. See
  examples on how to add value to a minted token.
  """
  alias KuberaDB.{MintedToken, Mint, Balance}
  alias KuberaMQ.Serializers.Transaction
  alias KuberaMQ.Entry

  @doc """
  Insert a new mint for a token, adding more value to it which can then be
  given to users.

  ## Examples

    res = Mint.insert(%{
      minted_token: minted_token,
      amount: 100_000,
      description: "Another mint bites the dust.",
      metadata: %{probably: "something useful. Or not."}
    })

    case res do
      {:ok, mint, response} ->
        # Everything went well, do something.
        # response is the response returned by the local ledger (Caishen for
        # example).
      {:error, code, description} ->
        # Something went wrong on the other side (Caishen maybe) and the
        # insert failed.
      {:error, changeset, nil} ->
        # Something went wrong, check the errors in the changeset!
    end

  """
  def insert(%{
    minted_token: minted_token,
    amount: amount,
    description: description,
    metadata: metadata
  }) do
    mint = insert(minted_token, amount, description)

    case mint do
      {:ok, mint} ->
        minted_token |> serialize(amount, metadata) |> genesis(mint)
      {:error, changeset} ->
        {:error, changeset, nil}
    end
  end

  defp genesis({:ok, data}, mint) do
    {:ok, mint} = Mint.confirm(mint)
    {:ok, mint, data}
  end
  defp genesis({:error, code, description}, mint) do
    {:error, mint, code, description}
  end
  defp genesis(data, mint) do
    data
    |> Entry.genesis
    |> genesis(mint)
  end

  defp insert(minted_token, amount, description) do
    Mint.insert(%{
      minted_token_id: minted_token.id,
      amount: amount,
      description: description
    })
  end

  defp serialize(minted_token, amount, metadata) do
    Transaction.serialize(%{
      from: genesis(),
      to: MintedToken.get_main_balance(minted_token),
      minted_token: minted_token,
      amount: amount,
      metadata: metadata
    })
  end

  defp genesis do
    {:ok, genesis} = Balance.genesis()
    genesis
  end
end
