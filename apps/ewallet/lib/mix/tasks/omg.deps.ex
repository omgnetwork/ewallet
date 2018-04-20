defmodule Mix.Tasks.Omg.Deps do
  @moduledoc """
  Retrieve dependencies for back-end and front-end apps in one go.

  ## Examples

  Simply run the following command:

      mix omg.deps
  """
  use Mix.Task

  @shortdoc "Retrieve dependencies for back-end and front-end apps in one go"

  def run(args) do
    Mix.shell().info("Fetching backend depedencies...")
    deps_backend(args)

    Mix.shell().info("Fetching frontend depedencies...")
    deps_frontend()
  end

  def deps_backend(args) do
    Mix.Task.run("deps.get", args)
  end

  def deps_frontend do
    System.cmd("yarn", ["install", "--non-interactive", "--color=always"],
                       cd: Path.expand("../../../../admin_panel/assets/", __DIR__),
                       into: IO.stream(:stdio, :line),
                       stderr_to_stdout: true)
  end
end
