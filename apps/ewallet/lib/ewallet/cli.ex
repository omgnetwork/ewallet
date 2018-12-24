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

defmodule EWallet.CLI do
  @moduledoc """
  Helper module for working with the command line interface.
  """

  import IO
  import IO.ANSI
  alias IO.ANSI.Docs

  def info(message), do: [:normal, message] |> format |> puts

  def debug(message), do: [:faint, message] |> format |> puts

  def success(message), do: [:green, message] |> format |> puts

  def warn(message), do: [:yellow, message] |> format |> puts

  def error(message), do: [:red, message] |> format |> puts

  def color(messages), do: messages |> format |> puts

  def heading(message), do: Docs.print_heading(message, width: 100)

  def print(message), do: Docs.print(message, width: 100)

  @spec halt(any()) :: no_return()
  def halt(message) do
    error(message)
    System.halt(1)
  end

  @doc """
    Prompts the user for input without revealing what has been entered.

    Since Elixir does not have this feature built-in,
    thanks to `Mix.Hex.Utils` for the workaround below.
  """
  def gets_sensitive(prompt) do
    pid = spawn_link(fn -> loop_gets_sensitive(prompt) end)
    ref = make_ref()
    value = IO.gets(prompt <> " ")

    send(pid, {:done, self(), ref})
    receive do: ({:done, ^pid, ^ref} -> :ok)

    value
  end

  defp loop_gets_sensitive(prompt) do
    receive do
      {:done, parent, ref} ->
        send(parent, {:done, self(), ref})
        IO.write(:standard_error, "\e[2K\r")
    after
      1 ->
        IO.write(:standard_error, "\e[2K\r#{prompt} ")
        loop_gets_sensitive(prompt)
    end
  end
end
