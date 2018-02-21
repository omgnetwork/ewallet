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
