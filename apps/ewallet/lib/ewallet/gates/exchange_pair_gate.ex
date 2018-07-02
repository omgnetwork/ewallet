defmodule EWallet.ExchangePairGate do
  @moduledoc """
  Handles the logic for manipulating an exchange pair.
  """
  alias EWallet.UUIDFetcher
  alias EWalletDB.ExchangePair

  @doc """
  Inserts an exchange pair.
  """
  @spec insert(map()) :: {:ok, [%ExchangePair{}]} | {:error, any()}
  def insert(attrs) do
    with {:ok, direct} <- insert(:direct, attrs),
         {:ok, opposite} <- insert(:opposite, attrs),
         pairs <- [direct, opposite],
         pairs <- Enum.reject(pairs, &is_nil/1) do
      {:ok, pairs}
    else
      error -> error
    end
  end

  # Only inserts the direct pair
  defp insert(:direct, attrs) do
    with %{} = attrs <- UUIDFetcher.replace_external_ids(attrs),
         {:ok, pair} <- ExchangePair.insert(attrs) do
      {:ok, pair}
    else
      error -> error
    end
  end

  # Only inserts the opposite pair if explicitly requested
  defp insert(:opposite, %{"create_opposite" => true} = attrs) do
    opposite_attrs =
      attrs
      |> Map.put("name", attrs["name"] <> " (opposite pair)")
      |> Map.put("from_token_id", attrs["to_token_id"])
      |> Map.put("to_token_id", attrs["from_token_id"])
      |> Map.put("rate", 1 / attrs["rate"])

    insert(:direct, opposite_attrs)
  end

  defp insert(:opposite, _), do: {:ok, nil}

  @doc """
  Updates an exchange pair.
  """
  @spec update(String.t(), map()) :: {:ok, %ExchangePair{}} | {:error, any()}
  def update(id, attrs) do
    with %{} = attrs <- UUIDFetcher.replace_external_ids(attrs),
         %ExchangePair{} = pair <- ExchangePair.get(id) || {:error, :exchange_pair_id_not_found},
         {:ok, updated} <- ExchangePair.update(pair, attrs) do
      {:ok, updated}
    else
      error -> error
    end
  end
end
