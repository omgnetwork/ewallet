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

defmodule EWalletDB.BlockchainValidator do
  @moduledoc """
  Custom validators that extend Ecto.Changeset's list of built-in validators.
  """
  alias Ecto.Changeset

  def validate_blockchain_address(changeset, field) do
    changeset
    |> Changeset.get_field(field)
    |> do_validate_blockchain_address(field, changeset)
  end

  defp do_validate_blockchain_address(nil, _field, changeset), do: changeset

  defp do_validate_blockchain_address(blockchain_address, field, changeset) do
    adapter = Application.get_env(:ewallet_db, :blockchain_adapter)

    case adapter.helper().adapter_address?(blockchain_address) do
      true ->
        changeset

      false ->
        Changeset.add_error(
          changeset,
          field,
          "is not a valid blockchain address",
          validation: :invalid_blockchain_address
        )
    end
  end

  def validate_blockchain_identifier(changeset, field) do
    inserted_identifier = Changeset.get_field(changeset, field)
    adapter = Application.get_env(:ewallet_db, :blockchain_adapter)
    blockchain_identifier = adapter.helper().identifier()

    case inserted_identifier do
      nil ->
        changeset

      ^blockchain_identifier ->
        changeset

      _ ->
        Changeset.add_error(
          changeset,
          field,
          "is not a valid blockchain identifier",
          validation: :invalid_blockchain_identifier
        )
    end
  end
end
