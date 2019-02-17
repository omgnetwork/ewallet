# Copyright 2018-2019 OmiseGO Pte Ltd
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

defmodule Utils.Helper.PidHelper do
  @moduledoc """
  Module helping out with PID <> String conversions.
  """

  def pid_to_binary(pid) when is_pid(pid) do
    "#PID" <> (pid |> :erlang.pid_to_list() |> :erlang.list_to_binary())
  end

  def pid_to_binary(port) when is_port(port) do
    port |> :erlang.port_to_list() |> :erlang.list_to_binary()
  end

  # the msg tracer seems to give us back the registered name
  def pid_to_binary(atom) when is_atom(atom) do
    atom |> :erlang.whereis() |> pid_to_binary
  end

  def pid_from_string("#PID" <> string) do
    string
    |> :erlang.binary_to_list()
    |> :erlang.list_to_pid()
  end

  def pid_from_string(string) do
    string
    |> :erlang.binary_to_list()
    |> :erlang.list_to_atom()
    |> :erlang.whereis()
  end
end
