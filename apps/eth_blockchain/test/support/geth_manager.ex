# Copyright 2019 OmiseGO Pte Ltd
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

defmodule EthBlockchain.GethManager do
  @moduledoc """
  Helper module for deployment of contracts to dev geth.
  """
  require Logger

  alias EthBlockchain.WaitFor

  @doc """
  Run geth in temp dir, kill it with SIGKILL when done.
  """
  def start do
    {:ok, _} = Application.ensure_all_started(:erlexec)
    DeferredConfig.populate(:ethereumex)
    {:ok, homedir} = Briefly.create(directory: true)

    geth_pid =
      launch(
        "geth --dev --dev.period=0 --rpc --rpc --rpcapi=personal,eth,web3 --nodiscover --datadir #{
          homedir
        } 2>&1"
      )

    {:ok, :ready} = WaitFor.eth_rpc()

    on_exit = fn -> stop(geth_pid) end

    {:ok, on_exit}
  end

  defp stop(pid) do
    # NOTE: monitor is required to stop_and_wait, don't know why?
    # `monitor: true` on run doesn't work
    _ = Process.monitor(pid)
    {:exit_status, _35_072} = Exexec.stop_and_wait(pid)
    :ok
  end

  # PRIVATE

  defp log_geth_output(line) do
    _ = Logger.debug("geth: " <> line)
    line
  end

  defp launch(cmd) do
    _ = Logger.debug("Starting geth")

    {:ok, geth_proc, _ref, [{:stream, geth_out, _stream_server}]} =
      Exexec.run(cmd, stdout: :stream, kill_command: "pkill -9 geth")

    wait_for_geth_start(geth_out)

    _ =
      %Task{} =
      fn ->
        geth_out |> Enum.each(&log_geth_output/1)
      end
      |> Task.async()

    geth_proc
  end

  def wait_for_start(outstream, look_for, timeout) do
    # Monitors the stdout coming out of a process for signal of successful startup
    waiting_task_function = fn ->
      outstream
      |> Stream.map(&log_geth_output/1)
      |> Stream.take_while(fn line -> not String.contains?(line, look_for) end)
      |> Enum.to_list()
    end

    waiting_task_function
    |> Task.async()
    |> Task.await(timeout)

    :ok
  end

  defp wait_for_geth_start(geth_out) do
    wait_for_start(geth_out, "HTTP endpoint opened", 15_000)
  end
end
