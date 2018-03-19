defmodule Mix.Tasks.Omg.Server do
  # This file is an edited version of Phoenix's `Mix.Tasks.Phx.Server`
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

  ## OmiseGO-specific options

  This task can also be run with the following flags:

  - `--no-watch` - disables watching and building when frontend assets change
  """

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
