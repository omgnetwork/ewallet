defmodule LoadTester.Scenarios.Index do
  use Chaperon.Scenario

  def run(session) do
    session
    |> get(
      "/",
      decode: :json,
      with_result: &log_output(&1, &2)
    )
  end

  defp log_output(session, result) do
    session
    |> log_info("Calling / returns: #{inspect(result)}")
  end
end
