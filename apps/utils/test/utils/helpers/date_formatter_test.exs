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

defmodule Utils.Helpers.DateFormatterTest do
  use ExUnit.Case, async: true
  alias EWallet.Errors.InvalidDateFormatError
  alias Utils.Helpers.DateFormatter

  describe "to_iso8601/1" do
    test "formats a valid naive date time" do
      naive_date = ~N[2000-01-01 10:01:02]
      formatted_date = DateFormatter.to_iso8601(naive_date)

      assert formatted_date == "2000-01-01T10:01:02Z"
    end

    test "formats a normal date time" do
      {:ok, date, 0} = DateTime.from_iso8601("2000-01-01T10:01:02Z")
      formatted_date = DateFormatter.to_iso8601(date)

      assert formatted_date == "2000-01-01T10:01:02Z"
    end

    test "Raise an exception if the type is not supported" do
      assert_raise InvalidDateFormatError, fn ->
        DateFormatter.to_iso8601("an invalid type")
      end
    end
  end
end
