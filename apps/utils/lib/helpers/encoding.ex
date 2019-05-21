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

defmodule Utils.Helpers.Encoding do
  @moduledoc false

  @spec to_hex(binary | non_neg_integer) :: binary
  def to_hex(non_hex)

  def to_hex(raw) when is_binary(raw), do: "0x" <> Base.encode16(raw, case: :lower)
  def to_hex(int) when is_integer(int), do: "0x" <> Integer.to_string(int, 16)

  @doc """
  Decodes to a raw binary, see `to_hex`
  """
  # because https://github.com/rrrene/credo/issues/583, we need to:
  # credo:disable-for-next-line Credo.Check.Consistency.SpaceAroundOperators
  @spec from_hex(<<_::16, _::_*8>>) :: binary
  def from_hex("0x" <> encoded) when is_binary(encoded) and rem(byte_size(encoded), 2) == 1 do
    from_hex("0x0#{encoded}")
  end

  def from_hex("0x" <> encoded) when is_binary(encoded) and rem(byte_size(encoded), 2) == 0 do
    Base.decode16!(encoded, case: :lower)
  end

  def from_hex(encoded) when is_binary(encoded) do
    Base.decode16!(encoded, case: :lower)
  end

  def sliced("0x" <> data) do
    data
  end

  @doc """
  Decodes to an integer, see `to_hex`
  """
  # because https://github.com/rrrene/credo/issues/583, we need to:
  # credo:disable-for-next-line Credo.Check.Consistency.SpaceAroundOperators
  @spec int_from_hex(<<_::16, _::_*8>>) :: non_neg_integer
  def int_from_hex("0x" <> encoded) do
    case Integer.parse(encoded, 16) do
      {result, ""} -> result
      :error -> 0
    end
  end

  @spec encode_unsigned(number()) :: binary()
  def encode_unsigned(0), do: <<>>
  def encode_unsigned(n), do: :binary.encode_unsigned(n)
end
