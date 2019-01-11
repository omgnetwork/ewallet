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

defmodule EWallet.DBCase do
  @moduledoc """
  A test case template for tests that need to connect to the DB.
  """
  use ExUnit.CaseTemplate
  import EWalletDB.Factory
  alias EWalletDB.Repo
  alias EWalletConfig.ConfigTestHelper

  defmacro __using__(_opts) do
    quote do
      use EWallet.Case
      import EWallet.DBCase
      import EWalletDB.Factory
      alias Ecto.Adapters.SQL.Sandbox
      alias EWalletDB.Repo
      alias EWalletDB.Account

      setup tags do
        :ok = Sandbox.checkout(EWalletDB.Repo)
        :ok = Sandbox.checkout(LocalLedgerDB.Repo)
        :ok = Sandbox.checkout(EWalletConfig.Repo)
        :ok = Sandbox.checkout(ActivityLogger.Repo)

        unless tags[:async] do
          Sandbox.mode(EWalletConfig.Repo, {:shared, self()})
          Sandbox.mode(EWalletDB.Repo, {:shared, self()})
          Sandbox.mode(LocalLedgerDB.Repo, {:shared, self()})
          Sandbox.mode(ActivityLogger.Repo, {:shared, self()})
        end

        config_pid = start_supervised!(EWalletConfig.Config)

        ConfigTestHelper.restart_config_genserver(
          self(),
          config_pid,
          EWalletConfig.Repo,
          [:ewallet_db, :ewallet],
          %{
            "enable_standalone" => false,
            "base_url" => "http://localhost:4000",
            "email_adapter" => "test"
          }
        )

        %{config_pid: config_pid}
      end
    end
  end

  def ensure_num_records(schema, num_required, attrs \\ %{}, count_field \\ :id) do
    num_remaining = num_required - Repo.aggregate(schema, :count, count_field)
    factory_name = get_factory(schema)

    insert_list(num_remaining, factory_name, attrs)
    Repo.all(schema)
  end
end
