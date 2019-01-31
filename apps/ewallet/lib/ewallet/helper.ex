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

defmodule EWallet.Helper do
  @moduledoc """
  The module for generic helpers.
  """

  @doc """
  Converts a list of strings to a list of existing atoms.

  If the string does not match an existing atom, it is skipped from the resulting list.
  """
  def to_existing_atoms(strings) do
    strings
    |> Enum.reduce([], &to_existing_atoms/2)
    |> Enum.reverse()
  end

  def to_existing_atoms(string, atom_list) do
    atom = String.to_existing_atom(string)
    [atom | atom_list]
  rescue
    ArgumentError -> atom_list
  end

  def to_boolean(s) when is_boolean(s), do: s
  def to_boolean(s) when is_binary(s), do: string_to_boolean(s)
  def to_boolean(s) when is_integer(s) and s >= 1, do: true
  def to_boolean(_), do: false

  def string_to_integer(string) do
    case Integer.parse(string, 10) do
      {amount, ""} ->
        {:ok, amount}

      _ ->
        {:error, :invalid_parameter,
         "Invalid parameter provided. String number is not a valid number: '#{string}'."}
    end
  end

  def strings_to_integers(strings) do
    amounts =
      Enum.map(strings, fn string ->
        case Integer.parse(string, 10) do
          {amount, ""} ->
            {:ok, amount}

          _ ->
            :error
        end
      end)

    case Enum.any?(amounts, fn amount -> amount == :error end) do
      true ->
        formatted_strings = Enum.join(strings, ", ")

        {:error, :invalid_parameter,
         "Invalid parameter provided. String numbers are not valid numbers: '#{formatted_strings}'."}

      false ->
        amounts
    end
  end

  def string_to_boolean(<<"T", _::binary>>), do: true
  def string_to_boolean(<<"Y", _::binary>>), do: true
  def string_to_boolean(<<"t", _::binary>>), do: true
  def string_to_boolean(<<"y", _::binary>>), do: true
  def string_to_boolean(<<"1", _::binary>>), do: true
  def string_to_boolean(_), do: false

  @doc """
  Checks if all `elements` exist within the `enumerable`.

  Membership is tested with the match (`===`) operator.
  """
  def members?(enumerable, elements) do
    Enum.all?(elements, fn element ->
      Enum.member?(enumerable, element)
    end)
  end

  @doc """
  Returns a path to static distribution. If SERVE_LOCAL_STATIC
  is true, it means that we want to serve directly from source tree
  instead of from the _build directory, so we're returning a relative
  path from a file.
  """
  def static_dir(app) do
    serve_local_static = System.get_env("SERVE_LOCAL_STATIC")

    case to_boolean(serve_local_static) do
      true ->
        Application.app_dir(app, "priv/static")

      false ->
        Path.expand("../../../#{app}/priv/static", __DIR__)
    end
  end
end
