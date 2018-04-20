defmodule Mix.Tasks.Omg.Deps do
  use Mix.Task

  @shortdoc "Retrieve dependencies for both back-end and front-end apps"

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
