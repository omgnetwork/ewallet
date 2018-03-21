# MIT License
# Copyright (c) 2014 Chris McCord
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

defmodule Mix.Tasks.Omg.Server do
  @moduledoc """
  Starts the application by configuring all endpoints servers to run.

  ## Command line options

  This task accepts the same command-line arguments as `run`.
  For additional information, refer to the documentation for
  `Mix.Tasks.Run`.

  For example, to run `omg.server` without checking dependencies:

      mix omg.server --no-deps-check

  The `--no-halt` flag is automatically added.

  ## OmiseGO-specific options

  This task can also be run with the following flags:

  - `--no-watch` - disables watching and building when frontend assets change
  """

  use Mix.Task
  alias Mix.Tasks.Run

  @shortdoc "Starts the eWallet applications and their servers"

  @doc false
  def run(args) do
    args
    |> configure_endpoints()
    |> configure_no_watch()
    |> configure_no_halt()
    |> Run.run()
  end

  # Let the UrlDispatcher know that the application is started as a server,
  # so that it can prepare the endpoints to be served.
  defp configure_endpoints(args) do
    Application.put_env(:url_dispatcher, :serve_endpoints, true)
    args # Doesn't touch the arguments, so send it back for further processing
  end

  defp configure_no_watch(args) do
    {parsed, args, _invalids} = OptionParser.parse(args, [no_watch: :boolean])
    if parsed[:no_watch], do: Application.put_env(:admin_panel, :start_with_no_watch, true)
    args # This is the arguments with `--no-watch` flag removed by `OptionParser.parse/2` above
  end

  defp configure_no_halt(args) do
    if iex_running?(), do: args, else: ["--no-halt" | args]
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) and IEx.started?
  end
end
