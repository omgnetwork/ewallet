# Copyright (c) 2019 Unnawut Leepaisalsuwanna

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

defmodule EIP55Test do
  use ExUnit.Case

  alias Utils.Helpers.EIP55

  doctest EIP55

  @subjects [
    {"0x5aaeb6053f3e94c9b9a09f33669435e7ef1beaed", "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed"},
    {"0x52908400098527886e0f7030069857d2e4169ee7", "0x52908400098527886E0F7030069857D2E4169EE7"},
    {"0x8617e340b3d01fa5f11f306f4090fd50e238070d", "0x8617E340B3D01FA5F11F306F4090FD50E238070D"},
    {"0xde709f2102306220921060314715629080e2fb77", "0xde709f2102306220921060314715629080e2fb77"},
    {"0x27b1fdb04752bbc536007a920d24acb045561c26", "0x27b1fdb04752bbc536007a920d24acb045561c26"},
    {"0xfb6916095ca1df60bb79ce92ce3ea74c37c5d359", "0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359"},
    {"0xdbf03b407c01e7cd3cbea99509d93f8dddc8c6fb", "0xdbF03B407c01E7cD3CBea99509d93f8DDDC8C6FB"},
    {"0xd1220a0cf47c7b9be7a2e6ba89f429762e7b9adb", "0xD1220A0cf47c7B9Be7A2E6BA89F429762e7b9aDb"}
  ]

  describe "encode/1" do
    test "encodes the address correctly" do
      Enum.each(@subjects, fn {address, target} ->
        assert EIP55.encode(address) == {:ok, target}
      end)
    end

    test "encodes the address correctly from a binary address" do
      Enum.each(@subjects, fn {"0x" <> hex, target} ->
        assert hex |> Base.decode16!(case: :lower) |> EIP55.encode() == {:ok, target}
      end)
    end

    test "returns {:error, :unrecognized_address_format} when given an invalid address" do
      assert EIP55.encode(nil) == {:error, :unrecognized_address_format}
      assert EIP55.encode(1234) == {:error, :unrecognized_address_format}
      assert EIP55.encode("0x") == {:error, :unrecognized_address_format}
      assert EIP55.encode("0x12345") == {:error, :unrecognized_address_format}
      assert EIP55.encode("not an adress") == {:error, :unrecognized_address_format}
      assert EIP55.encode(<<>>) == {:error, :unrecognized_address_format}
      assert EIP55.encode(<<1, 2, 3>>) == {:error, :unrecognized_address_format}

      assert EIP55.encode("0x12345678901234567890123456789012345678901234567890") ==
               {:error, :unrecognized_address_format}
    end
  end

  describe "valid?/1" do
    test "validates the address correctly" do
      Enum.each(@subjects, fn {_, checksummed} ->
        assert EIP55.valid?(checksummed)
      end)
    end

    test "returns false when given an invalid address" do
      assert EIP55.valid?(nil) === false
      assert EIP55.valid?(1234) === false
      assert EIP55.valid?("0x") === false
      assert EIP55.valid?("0x12345") === false
      assert EIP55.valid?("0x12345678901234567890123456789012345678901234567890") === false
      assert EIP55.valid?("not an adress") === false
      assert EIP55.valid?(<<>>) === false
      assert EIP55.valid?(<<1, 2, 3>>) === false
    end
  end
end
