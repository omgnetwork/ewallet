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

defmodule EWalletConfig.FileStorageSupervisor do
  @moduledoc """
  This module is used to supervise the Goth supervisor, needed to handle
  file uploads to GCS. In a nutshell, this module is works with a DynamicSupervisor
  in order to start or stop the Goth supervisor when needed (when the config is
  set to use GCS basically, else it will be stopped).
  """

  use GenServer
  require Logger

  @spec init(any()) :: {:ok, nil}
  def init(_args) do
    {:ok, nil}
  end

  @spec start_link() :: GenServer.on_start()
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec stop(pid()) :: :ok
  def stop(pid \\ __MODULE__) do
    GenServer.stop(pid)
  end

  @spec handle_call(:status, any(), nil) :: :ko
  def handle_call(:status, _from, nil), do: {:reply, :ko, nil}

  @spec handle_call(:status, any(), pid()) :: :ok
  def handle_call(:status, _from, pid), do: {:reply, :ok, pid}

  @spec handle_call(:start_goth, any(), nil) :: {:ok, pid()} | {:ok, nil}
  def handle_call(:start_goth, _from, nil) do
    goth =
      DynamicSupervisor.start_child(EWalletConfig.DynamicSupervisor, %{
        id: Goth.Supervisor,
        start: {Goth.Supervisor, :start_link, []}
      })

    case goth do
      {:ok, pid} ->
        {:reply, {:ok, pid}, pid}

      {:error, {:already_started, pid}} ->
        {:reply, {:ok, pid}, pid}

      error ->
        if Application.get_env(:ewallet, :env) != :test do
          Logger.warn("Failed to start Goth server, probably due to an invalid configuration.")
          Logger.warn(inspect(error))
        end

        {:reply, {:ok, nil}, nil}
    end
  end

  @spec handle_call(:start_goth, any(), pid()) :: {:ok, pid()}
  def handle_call(:start_goth, _from, pid), do: {:reply, {:ok, pid}, pid}

  @spec handle_call(:stop_goth, any(), nil) :: :ok
  def handle_call(:stop_goth, _from, nil), do: {:reply, :ok, nil}

  @spec handle_call(:stop_goth, any(), pid()) :: :ok
  def handle_call(:stop_goth, _from, pid) do
    DynamicSupervisor.terminate_child(EWalletConfig.DynamicSupervisor, pid)

    {:reply, :ok, nil}
  end
end
