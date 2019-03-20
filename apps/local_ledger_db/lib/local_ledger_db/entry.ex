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

defmodule LocalLedgerDB.Entry do
  @moduledoc """
  Ecto Schema representing entries. An entry is either a debit or credit
  and "moves" values around.
  """
  use Ecto.Schema
  import Ecto.{Changeset, Query}

  alias LocalLedgerDB.{
    Entry,
    Errors.InsufficientFundsError,
    Repo,
    Token,
    Transaction,
    Wallet
  }

  @primary_key {:uuid, Ecto.UUID, autogenerate: true}
  @timestamps_opts [type: :naive_datetime_usec]

  @credit "credit"
  @debit "debit"
  @types [@credit, @debit]

  def credit_type, do: @credit
  def debit_type, do: @debit

  schema "entry" do
    field(:amount, LocalLedger.Types.Integer)
    field(:type, :string)

    belongs_to(
      :token,
      Token,
      foreign_key: :token_id,
      references: :id,
      type: :string
    )

    belongs_to(
      :wallet,
      Wallet,
      foreign_key: :wallet_address,
      references: :address,
      type: :string
    )

    belongs_to(
      :transaction,
      Transaction,
      foreign_key: :transaction_uuid,
      references: :uuid,
      type: Ecto.UUID
    )

    timestamps()
  end

  @doc """
  Validate the entry attributes. This changeset is only used through the
  "cast_assoc" method in the Entry schema module.
  """
  def changeset(%Entry{} = entry, attrs) do
    entry
    |> cast(attrs, [:amount, :type, :token_id, :wallet_address, :transaction_uuid])
    |> validate_required([:amount, :type, :token_id, :wallet_address])
    |> validate_inclusion(:type, @types)
    |> foreign_key_constraint(:token_id)
    |> foreign_key_constraint(:wallet_address)
    |> foreign_key_constraint(:transaction_uuid)
  end

  @doc """
  Ensure that the given address has enough funds, else raise an
  InsufficientFundsError exception.
  """
  def check_balance(%{amount: amount_to_debit, token_id: token_id, address: address} = attrs) do
    current_amount = calculate_current_amount(address, token_id)

    unless current_amount - amount_to_debit >= 0 do
      raise InsufficientFundsError,
        message: InsufficientFundsError.error_message(current_amount, attrs)
    end

    :ok
  end

  @doc """
  Calculate the total balances for all the specified tokens associated
  with the given address.
  """
  def calculate_all_balances(address, options \\ %{}) do
    options = Map.put_new(options, :token_id, :all)
    credits = sum(address, Entry.credit_type(), options)
    debits = sum(address, Entry.debit_type(), options)

    credits |> subtract(debits) |> format()
  end

  defp subtract(credits, debits) do
    tokens = Enum.uniq(Map.keys(credits) ++ Map.keys(debits))

    Enum.map(tokens, fn token ->
      {token, (credits[token] || 0) - (debits[token] || 0)}
    end)
  end

  defp format(wallets), do: Enum.into(wallets, %{})

  defp sum(address, type, options) do
    address
    |> build_sum_query(type, options)
    |> Repo.all()
    |> Enum.into(%{}, fn {k, v} -> {k, Decimal.to_integer(v)} end)
  end

  defp build_sum_query(address, type, %{token_id: id, since: since, upto: upto}) do
    address
    |> build_sum_query(type, %{token_id: id})
    |> where([e], e.inserted_at > ^since)
    |> where([e], e.inserted_at <= ^upto)
  end

  defp build_sum_query(address, type, %{token_id: id, since: since}) do
    address
    |> build_sum_query(type, %{token_id: id})
    |> where([e], e.inserted_at > ^since)
  end

  defp build_sum_query(address, type, %{token_id: id, upto: upto}) do
    address
    |> build_sum_query(type, %{token_id: id})
    |> where([e], e.inserted_at <= ^upto)
  end

  defp build_sum_query(address, type, %{token_id: :all}) do
    Entry
    |> where([e], e.wallet_address == ^address and e.type == ^type)
    |> group_by([e], e.token_id)
    |> select([e, _], {e.token_id, sum(e.amount)})
  end

  defp build_sum_query(address, type, %{token_id: token_ids}) when is_list(token_ids) do
    Entry
    |> where([e], e.wallet_address == ^address and e.type == ^type and e.token_id in ^token_ids)
    |> group_by([e], e.token_id)
    |> select([e, _], {e.token_id, sum(e.amount)})
  end

  defp build_sum_query(address, type, %{token_id: id}) do
    address
    |> build_sum_query(type, %{token_id: :all})
    |> where([e], e.token_id == ^id)
  end

  @doc """
  Sum up all debit and credits for the given address/token_id combo before
  substracting one from the other.
  """
  def calculate_current_amount(address, token_id) do
    credit = sum_entries_amount(address, token_id, @credit) || Decimal.new(0)
    debit = sum_entries_amount(address, token_id, @debit) || Decimal.new(0)
    Decimal.to_integer(credit) - Decimal.to_integer(debit)
  end

  defp sum_entries_amount(address, token_id, type) do
    Repo.one(
      from(
        e in Entry,
        where: e.wallet_address == ^address and e.type == ^type and e.token_id == ^token_id,
        select: sum(e.amount)
      )
    )
  end
end
