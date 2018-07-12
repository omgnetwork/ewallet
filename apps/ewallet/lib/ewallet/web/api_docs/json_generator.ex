defmodule EWallet.Web.APIDocs.JSONGenerator do
  @moduledoc """
  Watches an OpenAPI YAML spec and converts it to a JSON spec.
  """
  use GenServer
  require Logger

  @spec start_link(keyword()) :: any()
  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @spec init(String.t()) :: {:ok, map()} | {:stop, atom()}
  def init(path) do
    with true <- File.exists?(path) || :file_not_found,
         {:ok, pid} = FileSystem.start_link(dirs: [path]),
         :ok <- FileSystem.subscribe(pid) do
      state = %{
        source: path,
        temp_dir: path |> Path.dirname() |> Path.join("spec_temp"),
        json_path: Path.join(Path.dirname(path), "spec.json")
      }

      {:ok, state}
    else
      error -> {:stop, error}
    end
  end

  @spec handle_info({:file_event, pid(), tuple()}, map()) :: {:noreply, map()}
  def handle_info({:file_event, _from, {path, events}}, state) do
    if Enum.member?(events, :modified) do
      Logger.info("Changes detected at #{path}. Regenerating JSON API specs...")
      :ok = generate(state)
    end

    {:noreply, state}
  end

  defp generate(state) do
    # `stderr_to_stdout: true` is used to suppresses the loud generator's output
    {_, 0} = System.cmd("java", generator_args(state), stderr_to_stdout: true)

    generated_path = Path.join(state.temp_dir, "openapi.json")
    :ok = File.rename(generated_path, state.json_path)
    {:ok, _} = File.rm_rf(state.temp_dir)

    Logger.info("JSON OpenAPI spec generated successfully at #{state.json_path}")

    :ok
  end

  defp generator_args(state) do
    generator = Path.expand("../../../../../../bin/openapi-generator-cli.jar", __DIR__)

    [
      "-jar",
      generator,
      "generate",
      "-i",
      state.source,
      "-g",
      "openapi",
      "-o",
      state.temp_dir
    ]
  end
end
