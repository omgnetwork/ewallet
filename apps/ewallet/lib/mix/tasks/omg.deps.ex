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
    System.cmd(
      "yarn",
      ["install", "--non-interactive", "--color=always"],
      cd: Path.expand("../../../../admin_panel/assets/", __DIR__),
      into: IO.stream(:stdio, :line),
      stderr_to_stdout: true
    )
  end
end
