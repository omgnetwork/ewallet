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

defmodule EWalletDB.BlockchainValidatorTest do
  use EWalletDB.SchemaCase, async: true
  import Ecto.Changeset
  import EWalletDB.BlockchainValidator

  defmodule SampleStruct do
    use Ecto.Schema

    schema "sample_structs" do
      field(:blockchain_address, :string)
      field(:blockchain_identifier, :string)
    end
  end

  describe "validate_blockchain_address/2" do
    test "returns valid if the blockchain address is valid" do
      adapter = Application.get_env(:ewallet_db, :blockchain_adapter)
      valid_address = adapter.helper().default_address

      struct = %SampleStruct{
        blockchain_address: valid_address
      }

      changeset =
        struct
        |> cast(%{blockchain_address: valid_address}, [:blockchain_address])
        |> validate_blockchain_address(:blockchain_address)

      assert changeset.valid?
    end

    test "returns valid if the blockchain address is nil" do
      struct = %SampleStruct{
        blockchain_address: nil
      }

      changeset =
        struct
        |> cast(%{blockchain_address: nil}, [:blockchain_address])
        |> validate_blockchain_address(:blockchain_address)

      assert changeset.valid?
    end

    test "returns invalid if the blockchain address is invalid" do
      invalid_address = "123"

      struct = %SampleStruct{
        blockchain_address: invalid_address
      }

      changeset =
        struct
        |> cast(%{blockchain_address: invalid_address}, [:blockchain_address])
        |> validate_blockchain_address(:blockchain_address)

      refute changeset.valid?
    end
  end

  describe "validate_blockchain_identifier/2" do
    test "returns valid if the blockchain identifier is valid" do
      valid_identifier = Application.get_env(:ewallet_db, :rootchain_identifier)

      struct = %SampleStruct{
        blockchain_identifier: valid_identifier
      }

      changeset =
        struct
        |> cast(%{blockchain_identifier: valid_identifier}, [:blockchain_identifier])
        |> validate_blockchain_identifier(:blockchain_identifier)

      assert changeset.valid?
    end

    test "returns valid if the blockchain identifier is nil" do
      struct = %SampleStruct{
        blockchain_identifier: nil
      }

      changeset =
        struct
        |> cast(%{blockchain_identifier: nil}, [:blockchain_identifier])
        |> validate_blockchain_identifier(:blockchain_identifier)

      assert changeset.valid?
    end

    test "returns invalid if the blockchain identifier is invalid" do
      invalid_identifier = "123"

      struct = %SampleStruct{
        blockchain_identifier: invalid_identifier
      }

      changeset =
        struct
        |> cast(%{blockchain_identifier: invalid_identifier}, [:blockchain_identifier])
        |> validate_blockchain_identifier(:blockchain_identifier)

      refute changeset.valid?
    end
  end
end
