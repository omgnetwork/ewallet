# Copyright 2019 OmiseGO
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule DB.SharedConnectionPool do
  @moduledoc """
  A singleton connection pool that can share connections across repos. Each pool is
  identified by a `shared_pool_id`.

  If `:shared_pool_id` is not given, a single connection pool is used across all repos
  that are configured to `pool: DB.SharedConnectionPool`.

  The actual pool GenServer and its logic are handled by `DBConnection.ConnectionPool`.
  """
  alias DBConnection.ConnectionPool

  @doc """
  Prepare a child spec for a connection pool.

  The returned spec will start only one pool for a given unique `:shared_pool_id` option.
  """
  def child_spec({mod, opts}) do
    opts = Keyword.put_new(opts, :name, pool_name(opts))
    Supervisor.Spec.worker(__MODULE__, [{mod, opts}])
  end

  @doc """
  Start a connection pool.
  """
  def start_link({mod, opts}) do
    case GenServer.start_link(ConnectionPool, {mod, opts}, start_opts(opts)) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      error -> error
    end
  end

  # Attempt to build a unique pool name using this module's full name and the `shared_pool_id`.
  defp pool_name(opts) do
    case Keyword.fetch(opts, :shared_pool_id) do
      {:ok, pool} -> String.to_atom("#{__MODULE__}-#{pool}")
      :error -> __MODULE__
    end
  end

  # Exact same as `DBConnection.ConnectionPool`
  defp start_opts(opts) do
    Keyword.take(opts, [:name, :spawn_opt])
  end
end
