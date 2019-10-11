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
  defmodule ToBooleanError do
    defexception message: "Could not represent the value as a boolean."

    def error_message(value),
      do: "Could not represent the value (#{inspect(value)}) as a boolean."
  end

  defmodule ToIntegerError do
    defexception message: "Could not represent the value as an integer."
    def error_message(value), do: "Could not represent the value (#{value}) as an integer."
  end

  def string_to_boolean(<<"T">>), do: true
  def string_to_boolean(<<"Y">>), do: true
  def string_to_boolean(<<"t">>), do: true
  def string_to_boolean(<<"y">>), do: true
  def string_to_boolean(<<"1">>), do: true
  def string_to_boolean(<<"True">>), do: true
  def string_to_boolean(<<"true">>), do: true
  def string_to_boolean(<<"yes">>), do: true
  def string_to_boolean(<<"Yes">>), do: true

  def string_to_boolean(<<"F">>), do: false
  def string_to_boolean(<<"N">>), do: false
  def string_to_boolean(<<"f">>), do: false
  def string_to_boolean(<<"n">>), do: false
  def string_to_boolean(<<"0">>), do: false
  def string_to_boolean(<<"False">>), do: false
  def string_to_boolean(<<"false">>), do: false
  def string_to_boolean(<<"no">>), do: false
  def string_to_boolean(<<"No">>), do: false

  def string_to_boolean(<<>>), do: nil

  def string_to_boolean(value) do
    {:error, :normalize_error, ToBooleanError.error_message(value)}
  end

  def string_to_boolean!(value) do
    case string_to_boolean(value) do
      {:error, :normalize_error, message} -> raise(ToBooleanError, message: message)
      converted -> converted
    end
  end

  # We need /1 and /2 separated, because if no default is specified, the app
  # should crash, trying to parse nil as a bool/bin/int
  def to_boolean(s) when is_boolean(s), do: s
  def to_boolean(s) when is_binary(s), do: string_to_boolean(s)
  def to_boolean(s) when is_integer(s) and s >= 1, do: true
  def to_boolean(value), do: {:error, :normalize_error, ToBooleanError.error_message(value)}

  def to_boolean!(value) do
    case to_boolean(value) do
      {:error, :normalize_error, message} -> raise(ToBooleanError, message: message)
      converted -> converted
    end
  end

  # Can be used when having a default value is fine, like DEBUG for seeds
  def to_boolean(nil, default), do: default
  def to_boolean(s, _) when is_boolean(s), do: s
  def to_boolean(s, _) when is_binary(s), do: string_to_boolean(s)
  def to_boolean(s, _) when is_integer(s) and s >= 1, do: true
  def to_boolean(_, default), do: default

  def to_integer(<<_::binary>> = s), do: :erlang.binary_to_integer(s)
  def to_integer([_ | _] = s), do: :erlang.list_to_integer(s)
  def to_integer(s) when is_integer(s), do: s
  def to_integer(s) when is_float(s), do: :erlang.round(s)
  def to_integer(value), do: {:error, :normalize_error, ToIntegerError.error_message(value)}

  def to_integer!(value) do
    case to_integer(value) do
      {:error, :normalize_error, message} -> raise(ToIntegerError, message: message)
      converted -> converted
    end
  end

  # Converts a comma-separated string to a list of strings
  def to_strings(s) do
    s
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end
end
