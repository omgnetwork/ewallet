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

defmodule Blockchain.Backend do
  @moduledoc false

  @typep server :: GenServer.server()
  @typep from :: GenServer.from()
  @typep state :: {atom(), map()}

  @typep backend :: Blockchain.backend()
  @typep call :: Blockchain.call()
  @typep mfargs :: {module(), atom(), [term()]}

  @typep resp(ret) :: ret | {:error, atom()}
  @typep reply(ret) :: {:reply, resp(ret), state()}

  ## Genserver
  ##

  use GenServer
  require Logger

  @doc """
  Starts Blockchain.Backend.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    :ok = Logger.info("Running Blockchain Backend supervisor.")

    {supervisor, opts} = Keyword.pop(opts, :supervisor)
    {backends, opts} = Keyword.pop(opts, :backends, [])
    {named, opts} = Keyword.pop(opts, :named, false)

    opts =
      case named do
        true ->
          Keyword.merge(opts, name: __MODULE__)

        false ->
          opts
      end

    GenServer.start_link(__MODULE__, {supervisor, backends}, opts)
  end

  @doc """
  Initialize the registry.
  """
  @spec init({atom(), list()}) :: {:ok, state()}
  def init({supervisor, backends}) do
    handlers =
      Enum.into(backends, %{}, fn {backend, mod} ->
        {backend, normalize_backend_mod(mod)}
      end)

    {:ok, {supervisor, handlers}}
  end

  @doc """
  Stops Blockchain.Backend.
  """
  @spec stop(server()) :: :ok
  def stop(pid \\ __MODULE__) do
    :ok = Logger.info("Stopping Blockchain Backend supervisor")
    GenServer.stop(pid)
  end

  ## Utilities
  ##

  @spec backend_name(backend()) :: atom()
  defp backend_name({backend, wallet_id}) do
    case wallet_id do
      nil ->
        String.to_atom("backend-#{backend}")

      n ->
        String.to_atom("backend-#{backend}-#{n}")
    end
  end

  @spec normalize_backend_mod(module() | mfargs()) :: mfargs()
  defp normalize_backend_mod(module) when is_atom(module) do
    {module, :start_link, []}
  end

  defp normalize_backend_mod({module, func, args}) do
    {module, func, args}
  end

  @spec ensure_backend_started(atom() | backend(), state()) :: resp({:ok, server()})
  defp ensure_backend_started(backend, state) when is_atom(backend) do
    ensure_backend_started({backend, nil}, state)
  end

  defp ensure_backend_started({backend, _id} = backend_spec, {supervisor, handlers}) do
    case handlers do
      %{^backend => mfargs} ->
        retval =
          DynamicSupervisor.start_child(supervisor, %{
            id: backend_name(backend_spec),
            start: mfargs,
            restart: :temporary
          })

        case retval do
          {:ok, pid} ->
            {:ok, pid}

          error ->
            :ok = Logger.error("Failed to start backend for #{backend}: #{inspect(error)}")
            {:error, :start_failed}
        end

      _ ->
        {:error, :no_handler}
    end
  end

  ## Callbacks
  ##

  @doc """
  Handles the call call from the client API call/4.
  """
  @spec handle_call({:call, backend(), call()}, from(), state()) :: reply({:ok, any()})
  def handle_call({:call, backend_spec, func_spec}, _from, state) do
    case ensure_backend_started(backend_spec, state) do
      {:ok, pid} ->
        try do
          {:reply, {:ok, GenServer.call(pid, func_spec)}, state}
        after
          GenServer.stop(pid)
        end

      error ->
        {:reply, error, state}
    end
  end

  ## Client API
  ##

  @doc """
  Pass a tuple of `{function, arglist}` to the appropriate backend.

  Returns `{:ok, response}` if the request was successful or
  `{:error, error_code}` in case of failure.
  """
  @spec call(atom() | backend(), call()) :: resp({:ok, any()})
  @spec call(atom() | backend(), call(), server()) :: resp({:ok, any()})
  def call(backend_spec, func_spec, pid \\ __MODULE__)

  def call(backend_spec, func_spec, pid) do
    case GenServer.call(pid, {:call, backend_spec, func_spec}) do
      {:ok, resp} ->
        resp

      error ->
        error
    end
  end
end
