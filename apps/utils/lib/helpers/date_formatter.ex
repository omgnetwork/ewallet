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

defmodule Utils.Helpers.DateFormatter do
  @moduledoc """
  This module allows formatting of a date (naive or date time) into an iso8601 string.
  """

  alias EWallet.Errors.InvalidDateFormatError

  @doc """
  Parses the given date time to an iso8601 string.
  """
  def to_iso8601(%DateTime{} = date) do
    DateTime.to_iso8601(date)
  end

  @doc """
  Parses the given NaiveDateTime to an iso8601 string.
  """
  def to_iso8601(%NaiveDateTime{} = date) do
    date
    |> DateTime.from_naive!("Etc/UTC")
    |> to_iso8601()
  end

  @doc """
  Returns nil if parsing nil.
  """
  def to_iso8601(nil) do
    nil
  end

  @doc """
  Raise a InvalidDateFormatError if the type is invalid.
  """
  def to_iso8601(_) do
    raise InvalidDateFormatError
  end
end
