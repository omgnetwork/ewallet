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

defmodule EWalletAPI.ChannelCase do
  @moduledoc """
  This module defines the test case to be used by
  channel tests.

  Such tests rely on `Phoenix.ChannelTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate
  use Phoenix.ChannelTest
  alias Ecto.Adapters.SQL.Sandbox
  import EWalletDB.Factory
  alias EWalletConfig.ConfigTestHelper
  alias EWalletDB.User

  @endpoint EWalletAPI.V1.Endpoint

  @provider_user_id "test_provider_user_id"

  using do
    quote do
      # Import conveniences for testing with channels
      use Phoenix.ChannelTest
      alias Ecto.Adapters.SQL.Sandbox
      import EWalletDB.Factory
      import EWalletAPI.ChannelCase

      # The default endpoint for testing
      @endpoint EWalletAPI.V1.Endpoint

      @provider_user_id unquote(@provider_user_id)
    end
  end

  setup tags do
    # Restarts `EWalletConfig.Config` so it does not hang on to a DB connection for too long.
    Supervisor.terminate_child(EWalletConfig.Supervisor, EWalletConfig.Config)
    Supervisor.restart_child(EWalletConfig.Supervisor, EWalletConfig.Config)

    :ok = Sandbox.checkout(EWalletConfig.Repo)
    :ok = Sandbox.checkout(EWalletDB.Repo)
    :ok = Sandbox.checkout(LocalLedgerDB.Repo)
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
      [:ewallet_db, :ewallet, :ewallet_api],
      %{
        "enable_standalone" => true,
        "base_url" => "http://localhost:4000",
        "email_adapter" => "test"
      }
    )

    {:ok, _user} =
      :user
      |> params_for(%{provider_user_id: @provider_user_id})
      |> User.insert()

    :ok
  end

  def get_test_user, do: User.get_by_provider_user_id(@provider_user_id)

  def test_socket(provider_user_id \\ @provider_user_id) do
    socket("test", %{
      auth: %{authenticated: true, end_user: User.get_by_provider_user_id(provider_user_id)}
    })
  end

  def test_with_topic(topic, channel, provider_user_id \\ @provider_user_id) do
    subscribe_and_join(test_socket(provider_user_id), channel, topic)
  end

  def assert_success({res, _, socket}, topic) do
    assert res == :ok
    assert socket.topic == topic
  end

  def assert_failure({res, code}, error) do
    assert res == :error
    assert code == error
  end
end
