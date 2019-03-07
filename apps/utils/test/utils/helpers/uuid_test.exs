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

defmodule Utils.Helpers.UUIDTest do
  use ExUnit.Case, async: true
  alias Utils.Helpers.UUID

  describe "get_uuids/1" do
    test "maps a list of records to a list of uuids" do
      record_1 = %{uuid: "00000000-0000-0000-0000-000000000000"}
      record_2 = %{uuid: "00000000-0000-0000-0000-000000000001"}
      record_3 = %{uuid: "00000000-0000-0000-0000-000000000002"}
      res = UUID.get_uuids([record_1, record_2, record_3])

      assert res == [record_1.uuid, record_2.uuid, record_3.uuid]
    end
  end
end
