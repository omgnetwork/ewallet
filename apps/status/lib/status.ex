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

defmodule Status do
  @moduledoc """
  Top level application module.
  """
  use Application
  alias Status.Metric.Recorder
  alias Utils.Helpers.Normalize

  def start(_type, _args) do
    DeferredConfig.populate(:status)
    import Supervisor.Spec, warn: false

    metrics =
      Enum.map(vm_metrics(), fn {name, invoke} ->
        Recorder.prepare_child(%Recorder{
          name: name,
          fn: invoke,
          reporter: &Appsignal.set_gauge/3
        })
      end)

    Supervisor.start_link(metrics, strategy: :one_for_one, name: Status.Supervisor)
  end

  @spec vm_metrics :: maybe_improper_list(atom(), fun()) | []
  defp vm_metrics, do: do_vm_metrics(is_enabled?() || false)

  defp do_vm_metrics(false), do: []

  defp do_vm_metrics(true) do
    memory =
      for type <- ~w(total processes ets binary atom atom_used)a,
          do: {String.to_atom("erlang_memory_#{type}"), fn -> :erlang.memory(type) end}

    system_info =
      for type <- ~w(schedulers atom_count process_count port_count)a,
          do: {String.to_atom("erlang_system_info_#{type}"), fn -> :erlang.system_info(type) end}

    other = [
      {:erlang_uptime, fn -> :erlang.statistics(:wall_clock) |> elem(0) |> Kernel.div(1000) end},
      {:erlang_io_input_kb,
       fn ->
         {{:input, input}, {:output, _output}} = :erlang.statistics(:io)
         input |> Kernel.div(1024)
       end},
      {:erlang_io_output_kb,
       fn ->
         {{:input, _input}, {:output, output}} = :erlang.statistics(:io)
         output |> Kernel.div(1024)
       end},
      {:erlang_total_run_queue_lengths, fn -> :erlang.statistics(:total_run_queue_lengths) end},
      {:erlang_ets_count, fn -> length(:ets.all()) end}
    ]

    Enum.concat([memory, system_info, other])
  end

  @spec is_enabled?() :: boolean() | nil
  defp is_enabled?() do
    :status
    |> Application.get_env(:metrics)
    |> Normalize.to_boolean()
  end
end
