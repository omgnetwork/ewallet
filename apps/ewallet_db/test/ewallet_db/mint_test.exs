# Copyright 2018 OmiseGO Pte Ltd
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

defmodule EWalletDB.MintTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.Mint

  describe "Mint factory" do
    test_has_valid_factory(Mint)
  end

  describe "insert/1" do
    test_insert_generate_uuid(Mint, :uuid)
    test_insert_generate_external_id(Mint, :id, "mnt_")
    test_insert_generate_timestamps(Mint)
    test_insert_prevent_blank(Mint, :amount)
    test_insert_prevent_blank(Mint, :token_uuid)
  end
end
