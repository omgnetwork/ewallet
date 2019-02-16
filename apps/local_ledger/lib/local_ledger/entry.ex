# Copyright 2019 OmiseGO Pte Ltd
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

defmodule LocalLedger.Entry do
  @moduledoc """
  This module is responsible for preparing and formatting the entries
  before they are passed to a transaction to be inserted in the database.
  """
  alias LocalLedgerDB.{Entry, Token, Wallet}

  @doc """
  Get or insert the given token and all the given addresses before
  building a map representation usable by the LocalLedgerDB schemas.
  """
  def build_all(entries) do
    Enum.map(entries, fn attrs ->
      {:ok, token} = Token.get_or_insert(attrs["token"])
      {:ok, wallet} = Wallet.get_or_insert(attrs)

      %{
        type: attrs["type"],
        amount: attrs["amount"],
        token_id: token.id,
        wallet_address: wallet.address
      }
    end)
  end

  @doc """
  Extract the list of DEBIT addresses.
  """
  def get_addresses(entries) do
    entries
    |> Enum.filter(fn entry ->
      entry[:type] == Entry.debit_type()
    end)
    |> Enum.map(fn entry -> entry[:wallet_address] end)
  end

  @doc """
  Match when genesis is set to true and does... nothing.
  """
  def check_balance(_, %{genesis: true}) do
    :ok
  end

  @doc """
  Match when genesis is false and run the wallet check.
  """
  def check_balance(entries, %{genesis: _}) do
    check_balance(entries)
  end

  @doc """
  Check the current wallet amount for each DEBIT entry.
  """
  def check_balance(entries) do
    Enum.each(entries, fn entry ->
      if entry[:type] == Entry.debit_type() do
        Entry.check_balance(%{
          amount: entry[:amount],
          token_id: entry[:token_id],
          address: entry[:wallet_address]
        })
      end
    end)
  end
end
