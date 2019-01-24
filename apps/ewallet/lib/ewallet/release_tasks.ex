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

defmodule EWallet.ReleaseTasks do
  @moduledoc """
  Provides utility function for release tasks.
  """
  alias IO.ANSI

  @yes_params ["-y", "--yes", "--assume_yes"]
  @yes_inputs ["y", "Y", "yes", "YES", "Yes"]

  defmacro __using__(_opts) do
    quote do
      import EWallet.ReleaseTasks
    end
  end

  def ensure_app_started({app_name, _}), do: ensure_app_started(app_name)

  def ensure_app_started(app_name) do
    case Application.ensure_all_started(app_name) do
      {:ok, _} ->
        repos = Application.get_env(app_name, :ecto_repos, [])
        Enum.each(repos, & &1.start_link(pool_size: 1))

      _ ->
        nil
    end
  end

  def assume_yes?(args), do: Enum.any?(args, fn a -> a in @yes_params end)

  def confirm?(message) do
    # Same implementation as `Mix.Shell.IO.yes?/1` but needed here because
    # Mix is not available with distillery releases.
    # Link: https://github.com/elixir-lang/elixir/blob/v1.6.5/lib/mix/lib/mix/shell/io.ex#L54
    answer = IO.gets(message <> " [Yn] ")
    is_binary(answer) and String.trim(answer) in ["" | @yes_inputs]
  end

  def puts(message, log_level \\ :info)

  def puts(message, :success) do
    [:green, :bright, message]
    |> ANSI.format()
    |> IO.puts()
  end

  def puts(message, :error) do
    message = ANSI.format([:red, :bright, message])
    IO.puts(:stderr, message)
  end

  def puts(message, :info), do: IO.puts(message)

  def puts(message, _), do: puts(message, :info)

  def give_up do
    puts("Error: unknown error occured in release tasks. This is probably a bug.", :error)
    puts("Please file a bug report at https://github.com/omisego/ewallet/issues/new", :error)
    :init.stop(1)
  end
end
