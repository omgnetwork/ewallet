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

defmodule Utils.Helpers.UUID do
  @moduledoc """
  Helper module to check that a string is a valid UUID.
  """
  @regex ~r/[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}/
  def regex, do: @regex

  def valid?(uuid) do
    String.match?(uuid, @regex)
  end

  def get_uuids(list) do
    Enum.map(list, fn record -> record.uuid end)
  end
end
