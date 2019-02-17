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

# MIT License
# Copyright (c) 2014 Chris McCord
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software
# and associated documentation files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom
# the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
# ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

defmodule Mix.Tasks.Omg.Server do
  @moduledoc """
  Starts the application by configuring all endpoints servers to run.
  This task is intended to be run in development environment.

  ## Command line options

  This task accepts the same command-line arguments as `run`.
  For additional information, refer to the documentation for
  `Mix.Tasks.Run`.

  For example, to run `omg.server` without checking dependencies:

      mix omg.server --no-deps-check

  The `--no-halt` flag is automatically added in case `omg.server`
  is invoked directly without IEx console attached. If you wish to run
  `omg.server` with IEx without starting the server, you can use:

      iex -S mix omg.server --no-serve

  ## OmiseGO-specific options

  This task can also be run with the following flags:

  - `--no-watch` - disables watching and building when frontend assets change
  - `--no-serve` - disables serving endpoints
  """

  use Mix.Task
  alias Mix.Tasks.Run

  @shortdoc "Starts the eWallet applications and their servers"

  @doc false
  def run(args) do
    System.put_env("WEBPACK_WATCH", "true")
    System.put_env("SERVE_ENDPOINTS", "true")
    System.put_env("SERVE_LOCAL_STATIC", "true")

    run(args, [])
  end

  defp run(["--no-watch" | t], args2) do
    System.put_env("WEBPACK_WATCH", "false")
    run(t, args2)
  end

  defp run(["--no-serve" | t], args2) do
    System.put_env("SERVE_ENDPOINTS", "false")
    run(t, args2)
  end

  defp run([h | t], args2), do: run(t, args2 ++ [h])

  defp run([], args2) do
    case iex_running?() do
      true ->
        Run.run(args2)

      _ ->
        Run.run(args2 ++ ["--no-halt"])
    end
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) and IEx.started?()
  end
end
