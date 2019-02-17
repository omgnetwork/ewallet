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

defmodule Utils.Helpers.Normalize do
  @moduledoc """
  Module to normalize strings.
  """

  def string_to_boolean(<<"T", _::binary>>), do: true
  def string_to_boolean(<<"Y", _::binary>>), do: true
  def string_to_boolean(<<"t", _::binary>>), do: true
  def string_to_boolean(<<"y", _::binary>>), do: true
  def string_to_boolean(<<"1", _::binary>>), do: true
  def string_to_boolean(_), do: false

  def to_boolean(s) when is_boolean(s), do: s
  def to_boolean(s) when is_binary(s), do: string_to_boolean(s)
  def to_boolean(s) when is_integer(s) and s >= 1, do: true
  def to_boolean(_), do: false
end
