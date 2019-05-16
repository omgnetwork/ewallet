# Copyright 2018-2019 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule EWallet.ExchangePairGate do
  @moduledoc """
  Handles the logic for manipulating an exchange pair.
  """
  alias EWallet.UUIDFetcher
  alias EWalletDB.{ExchangePair, Repo}
  alias EWallet.Web.Paginator

  @doc """
  Inserts an exchange pair.
  """
  @spec insert(map()) ::
          {:ok, [%ExchangePair{}]}
          | {:error, atom() | Ecto.Changeset.t()}
          | {:error, atom(), String.t()}
  def insert(%{"rate" => rate} = attrs) when is_binary(rate) do
    case cast_rate(attrs) do
      {:ok, casted} -> insert(casted)
      error -> error
    end
  end

  def insert(attrs) do
    Repo.transaction(fn ->
      with {:ok, direct} <- insert(:direct, attrs),
           {:ok, opposite} <- insert(:opposite, attrs),
           pairs <- [direct, opposite],
           pairs <- Enum.reject(pairs, &is_nil/1) do
        pairs
      else
        {:error, error} -> Repo.rollback(error)
      end
    end)
  end

  # Only inserts the direct pair
  defp insert(:direct, attrs) do
    with %{} = attrs <- UUIDFetcher.replace_external_ids(attrs),
         {:ok, pair} <- ExchangePair.insert(attrs) do
      {:ok, pair}
    else
      {:error, %{errors: [from_token: {"has already been taken", _}]}} ->
        {:error, :exchange_pair_already_exists}

      error ->
        error
    end
  end

  # Only inserts the opposite pair if explicitly requested
  defp insert(:opposite, %{"sync_opposite" => true} = attrs) do
    opposite_attrs =
      attrs
      |> Map.put("from_token_id", attrs["to_token_id"])
      |> Map.put("to_token_id", attrs["from_token_id"])
      |> Map.put("rate", 1 / attrs["rate"])

    insert(:direct, opposite_attrs)
  end

  defp insert(:opposite, _), do: {:ok, nil}

  @doc """
  Updates an exchange pair.
  """
  @spec update(String.t(), map()) ::
          {:ok, [%ExchangePair{}]}
          | {:error, atom() | Ecto.Changeset.t()}
          | {:error, atom(), String.t()}
  def update(id, %{"rate" => rate} = attrs) when is_binary(rate) do
    case cast_rate(attrs) do
      {:ok, casted} -> update(id, casted)
      error -> error
    end
  end

  def update(id, attrs) do
    Repo.transaction(fn ->
      with {:ok, direct} <- update(:direct, id, attrs),
           {:ok, opposite} <- update(:opposite, direct, attrs),
           pairs <- [direct, opposite],
           pairs <- Enum.reject(pairs, &is_nil/1) do
        pairs
      else
        {:error, error} -> Repo.rollback(error)
      end
    end)
  end

  # Only updates the direct pair
  defp update(:direct, id, attrs) do
    case ExchangePair.get(id) do
      nil ->
        {:error, :exchange_pair_id_not_found}

      pair ->
        ExchangePair.update(pair, attrs)
    end
  end

  # Only updates the opposite pair if explicitly requested
  defp update(
         :opposite,
         direct_pair,
         %{"sync_opposite" => true, "originator" => originator} = direct_attrs
       ) do
    case ExchangePair.get_opposite_pair(direct_pair) do
      nil ->
        {:error, :exchange_opposite_pair_not_found}

      opposite_pair ->
        case direct_attrs["rate"] do
          nil ->
            {:ok, opposite_pair}

          rate ->
            ExchangePair.update(opposite_pair, %{
              "rate" => 1 / rate,
              "originator" => originator
            })
        end
    end
  end

  defp update(:opposite, _, _), do: {:ok, nil}

  defp cast_rate(%{"rate" => rate} = attrs) do
    case Float.parse(rate) do
      # Only a succesful parsing without any binary remainder shall proceed
      {parsed, ""} ->
        {:ok, Map.put(attrs, "rate", parsed)}

      _ ->
        {:error, :invalid_parameter,
         "Invalid parameter provided. `rate` cannot be parsed. Got: #{inspect(rate)}"}
    end
  end

  @doc """
  Deletes an exchange pair.
  """
  @spec delete(String.t(), map(), map()) ::
          {:ok, [%ExchangePair{}]} | {:error, atom() | Ecto.Changeset.t()}
  def delete(id, attrs, originator) do
    Repo.transaction(fn ->
      with {:ok, direct} <- delete(:direct, id, attrs, originator),
           {:ok, opposite} <- delete(:opposite, direct, attrs, originator),
           pairs <- [direct, opposite],
           pairs <- Enum.reject(pairs, &is_nil/1) do
        pairs
      else
        {:error, error} -> Repo.rollback(error)
      end
    end)
  end

  # Deletes the direct pair
  defp delete(:direct, id, _attrs, originator) do
    case ExchangePair.get(id) do
      nil ->
        {:error, :exchange_pair_id_not_found}

      pair ->
        ExchangePair.delete(pair, originator)
    end
  end

  # Deletes the opposite pair if explicitly requested
  defp delete(:opposite, direct_pair, %{"sync_opposite" => true}, originator) do
    case ExchangePair.get_opposite_pair(direct_pair) do
      nil ->
        {:error, :exchange_opposite_pair_not_found}

      opposite_pair ->
        ExchangePair.delete(opposite_pair, originator)
    end
  end

  defp delete(:opposite, _, _, _), do: {:ok, nil}

  def add_opposite_pairs(%Paginator{data: exchange_pairs} = paginator) do
    updated_pairs = add_opposite_pairs(exchange_pairs)

    Map.put(paginator, :data, updated_pairs)
  end

  def add_opposite_pairs(exchange_pairs) when is_list(exchange_pairs) do
    exchange_pairs
    |> ExchangePair.get_opposite_pairs()
    |> insert_opposite_pairs(exchange_pairs)
  end

  def add_opposite_pair(%ExchangePair{} = exchange_pair) do
    exchange_pair
    |> ExchangePair.get_opposite_pair()
    |> insert_opposite_pair(exchange_pair)
  end

  defp insert_opposite_pairs(opposites, exchange_pairs) do
    Enum.map(exchange_pairs, fn exchange_pair ->
      opposites
      |> Enum.find(fn opposite ->
        exchange_pair.from_token_uuid == opposite.to_token_uuid &&
          exchange_pair.to_token_uuid == opposite.from_token_uuid
      end)
      |> insert_opposite_pair(exchange_pair)
    end)
  end

  defp insert_opposite_pair(opposite_pair, exchange_pair) do
    Map.put(exchange_pair, :opposite_exchange_pair, opposite_pair)
  end
end
