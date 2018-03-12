defmodule Mix.Tasks.Omg.Server do
  @moduledoc """
  This file is an edited version of Phoenix's `Mix.Tasks.Phx.Server`
  """
  
  # MIT License
  # Copyright (c) 2014 Chris McCord
  #
  # Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
  #
  # The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
  #
  # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

  use Mix.Task
  alias Mix.Tasks.Run

  @shortdoc "Starts the eWallet applications and their servers"

  @moduledoc """
  Starts the application by configuring all endpoints servers to run.

  ## Command line options

  This task accepts the same command-line arguments as `run`.
  For additional information, refer to the documentation for
  `Mix.Tasks.Run`.

  For example, to run `omg.server` without checking dependencies:

      mix omg.server --no-deps-check

  The `--no-halt` flag is automatically added.
  """

  @doc false
  def run(args) do
    Application.put_env(:url_dispatcher, :serve_endpoints, true)
    Run.run run_args() ++ args
  end

  defp run_args do
    if iex_running?(), do: [], else: ["--no-halt"]
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) and IEx.started?
  end
end
