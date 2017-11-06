defmodule Kubera.Transaction do
  @moduledoc """
  Handles the logic for a transfer of value between two addresses.
  """
  alias KuberaMQ.Serializers.Transaction
  alias KuberaMQ.Entry
  alias KuberaDB.{User, MintedToken}

  @doc """
  Initialize a credit transaction
  """
  def init_credit(%{
    "provider_user_id" => provider_user_id,
    "symbol" => symbol,
    "amount" => _,
    "metadata" => _
  } = attrs) do
    provider_user_id
    |> load_records(symbol)
    |> init_credit(attrs)
  end
  def init_credit({:error, code}, _), do: {:error, code}
  def init_credit({:ok, user, minted_token}, attrs) do
    from = MintedToken.get_main_balance(minted_token)
    to = User.get_main_balance(user)
    init(attrs, minted_token, from, to)
  end

  @doc """
  Initialize a debit transaction
  """
  def init_debit(%{
    "provider_user_id" => provider_user_id,
    "symbol" => symbol,
    "amount" => _,
    "metadata" => _
  } = attrs) do
    provider_user_id
    |> load_records(symbol)
    |> init_debit(attrs)
  end
  def init_debit({:error, code}, _), do: {:error, code}
  def init_debit({:ok, user, minted_token}, attrs) do
    from = User.get_main_balance(user)
    to = MintedToken.get_main_balance(minted_token)
    init(attrs, minted_token, from, to)
  end

  defp init(%{
    "amount" => amount,
    "metadata" => metadata
  }, minted_token, from_balance, to_balance) do
    {
      :ok,
      %{
        from: from_balance,
        to: to_balance,
        minted_token: minted_token,
        amount: amount,
        metadata: metadata
      }
    }
  end

  defp load_records(provider_user_id, symbol) do
    user = User.get_by_provider_user_id(provider_user_id)
    minted_token = MintedToken.get(symbol)
    load_records({user, minted_token})
  end
  defp load_records({nil, _}), do: {:error, :provider_user_id_not_found}
  defp load_records({_, nil}), do: {:error, :minted_token_not_found}
  defp load_records({user, minted_token}), do: {:ok, user, minted_token}

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
  def create(attrs) do
    attrs
    |> Transaction.serialize()
    |> Entry.insert()
  end
end
