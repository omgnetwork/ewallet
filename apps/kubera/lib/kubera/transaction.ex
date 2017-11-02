defmodule Kubera.Transaction do
  @moduledoc """
  Handles the logic for a transfer of value between two addresses.
  """
  alias KuberaMQ.Serializers.Transaction
  alias KuberaMQ.Entry
  alias KuberaDB.{User, MintedToken}

  def init(%{"provider_user_id" => provider_user_id, "symbol" => symbol,
             "amount" => amount, "metadata" => metadata}) do
    user = User.get_by_provider_user_id(provider_user_id)
    minted_token = MintedToken.get(symbol)

    %{
      from: MintedToken.get_main_balance(minted_token),
      to: User.get_main_balance(user),
      minted_token: minted_token,
      amount: amount,
      metadata: metadata
    }
  end

  @doc """
  Initiate a transfer between the balance 'from' to the balance 'to'.

  ## Examples

    Transaction.create(%{
      from: from_balance,
      to: to_balance,
      minted_token: minted_token,
      amount: 100_000,
      metadata: %{}
    }, fn res ->
      case res do
        {:ok, data} ->
          # The transaction was a success!
        {:error, code, description} ->
          # The transaction failed... Check the code and description to see
          # what went wrong.
      end
    end)

  """
  def create(attrs, callback) do
    data = Transaction.serialize(attrs)
    Entry.insert(data, callback)
  end
end
