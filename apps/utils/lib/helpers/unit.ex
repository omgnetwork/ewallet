# Copyright 2017-2019 OmiseGO Pte Ltd
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

defmodule Utils.Helpers.Unit do
  @moduledoc """
  Module to perform unit conversions.
  """

  @doc """
  Converts a number of decimal points to subunit value,
  useful for preparing `subunit_to_unit` values.
  """
  def decimals_to_subunit(decimals), do: :math.pow(10, decimals)
end
