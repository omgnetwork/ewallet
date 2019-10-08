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

defmodule EthBlockchain.TransactionListenerTest do
  use EthBlockchain.EthBlockchainCase, async: true

  alias EthBlockchain.{TransactionListener, DumbSubscriber}

  def get_attrs(map \\ %{}) do
    Map.merge(
      %{
        id: "fake_id",
        interval: 100,
        is_childchain_transaction: false,
        blockchain_adapter_pid: nil,
        node_adapter: nil
      },
      map
    )
  end

  describe "start_link/1" do
    test "starts a new server" do
      assert {:ok, pid} = TransactionListener.start_link(get_attrs())
      assert is_pid(pid)
      assert GenServer.stop(pid) == :ok
    end
  end

  describe "init/1" do
    test "inits with empty map" do
      assert {:ok,
              %{
                timer: _,
                interval: 100,
                is_childchain_transaction: false,
                tx_hash: "fake_id",
                transaction: nil,
                blockchain_adapter_pid: nil,
                node_adapter: nil,
                subscribers: []
              }, {:continue, :start_polling}} = TransactionListener.init(get_attrs())
    end
  end

  describe "subscribe/2" do
    test "subscribes a listener" do
      {:ok, pid} = TransactionListener.start_link(get_attrs())
      {:ok, subscriber_pid} = DumbSubscriber.start_link(%{})

      :ok = GenServer.call(pid, {:subscribe, subscriber_pid})
      %{subscribers: [state_sub_pid]} = :sys.get_state(pid)
      assert subscriber_pid == state_sub_pid

      assert GenServer.stop(pid) == :ok
    end

    test "prevent same subscriber from re-subscribing" do
      {:ok, pid} = TransactionListener.start_link(get_attrs())
      {:ok, subscriber_pid} = DumbSubscriber.start_link(%{})

      :ok = GenServer.call(pid, {:subscribe, subscriber_pid})
      %{subscribers: [state_sub_pid]} = :sys.get_state(pid)
      assert subscriber_pid == state_sub_pid

      {:error, :already_subscribed} = GenServer.call(pid, {:subscribe, subscriber_pid})

      %{subscribers: [state_sub_pid]} = :sys.get_state(pid)
      assert subscriber_pid == state_sub_pid

      assert GenServer.stop(pid) == :ok
    end
  end

  describe "unsubscribe/2" do
    test "unsubscribes listeners" do
      {:ok, pid} = TransactionListener.start_link(get_attrs())
      {:ok, subscriber_pid_1} = DumbSubscriber.start_link(%{})
      {:ok, subscriber_pid_2} = DumbSubscriber.start_link(%{})

      :ok = GenServer.call(pid, {:subscribe, subscriber_pid_1})
      :ok = GenServer.call(pid, {:subscribe, subscriber_pid_2})
      %{subscribers: subscribers} = :sys.get_state(pid)
      assert subscribers == [subscriber_pid_2, subscriber_pid_1]

      :ok = GenServer.cast(pid, {:unsubscribe, subscriber_pid_2})
      %{subscribers: subscribers} = :sys.get_state(pid)
      assert subscribers == [subscriber_pid_1]

      :ok = GenServer.cast(pid, {:unsubscribe, subscriber_pid_1})

      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          refute Process.alive?(pid)
      end
    end

    test "unsubscribes an already unsubscribed subscriber" do
      {:ok, pid} = TransactionListener.start_link(get_attrs())
      {:ok, subscriber_pid_1} = DumbSubscriber.start_link(%{})
      {:ok, subscriber_pid_2} = DumbSubscriber.start_link(%{})

      :ok = GenServer.call(pid, {:subscribe, subscriber_pid_1})
      :ok = GenServer.call(pid, {:subscribe, subscriber_pid_2})
      %{subscribers: subscribers} = :sys.get_state(pid)
      assert subscribers == [subscriber_pid_2, subscriber_pid_1]

      :ok = GenServer.cast(pid, {:unsubscribe, subscriber_pid_2})
      %{subscribers: subscribers} = :sys.get_state(pid)
      assert subscribers == [subscriber_pid_1]

      :ok = GenServer.cast(pid, {:unsubscribe, subscriber_pid_2})
      %{subscribers: subscribers} = :sys.get_state(pid)
      assert subscribers == [subscriber_pid_1]

      :ok = GenServer.cast(pid, {:unsubscribe, subscriber_pid_1})

      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, _, _} ->
          refute Process.alive?(pid)
      end
    end
  end

  describe "run/1" do
    test "handles a valid rootchain transaction" do
      {:ok, pid} = TransactionListener.start_link(get_attrs(%{id: "valid"}))
      # Subscribe to the subscriber to get updates
      {:ok, subscriber_pid} = DumbSubscriber.start_link(%{subscriber: self()})
      :ok = GenServer.call(pid, {:subscribe, subscriber_pid})

      # The Dumb Subscriber stops after receiving two confirmations_count,
      # ensuring the listener has submitted at least two events, testing the tick + run
      # functions
      receive do
        state ->
          assert state[:tx_hash] == "valid"
      end

      assert GenServer.stop(subscriber_pid) == :ok
      assert GenServer.stop(pid) == :ok
    end

    test "handles a valid childchain transaction" do
      {:ok, pid} =
        TransactionListener.start_link(get_attrs(%{id: "valid", is_childchain_transaction: true}))

      # Subscribe to the subscriber to get updates
      {:ok, subscriber_pid} = DumbSubscriber.start_link(%{subscriber: self()})
      :ok = GenServer.call(pid, {:subscribe, subscriber_pid})

      # The Dumb Subscriber stops after receiving two confirmations_count,
      # ensuring the listener has submitted at least two events, testing the tick + run
      # functions
      receive do
        state ->
          assert state[:tx_hash] == "valid"
      end

      assert GenServer.stop(subscriber_pid) == :ok
      assert GenServer.stop(pid) == :ok
    end

    test "handles a not found rootchain transaction" do
      {:ok, pid} = TransactionListener.start_link(get_attrs(%{id: "not_found"}))
      {:ok, subscriber_pid} = DumbSubscriber.start_link(%{subscriber: self()})
      :ok = GenServer.call(pid, {:subscribe, subscriber_pid})

      receive do
        state ->
          assert state[:error] == :not_found
      end

      assert GenServer.stop(subscriber_pid) == :ok
      assert GenServer.stop(pid) == :ok
    end

    test "handles a not found childchain transaction" do
      {:ok, pid} =
        TransactionListener.start_link(
          get_attrs(%{id: "not_found", is_childchain_transaction: true})
        )

      {:ok, subscriber_pid} = DumbSubscriber.start_link(%{subscriber: self()})
      :ok = GenServer.call(pid, {:subscribe, subscriber_pid})

      receive do
        state ->
          assert state[:error] == :not_found
      end

      assert GenServer.stop(subscriber_pid) == :ok
      assert GenServer.stop(pid) == :ok
    end

    test "handles a failed transaction" do
      {:ok, pid} = TransactionListener.start_link(get_attrs(%{id: "failed"}))
      {:ok, subscriber_pid} = DumbSubscriber.start_link(%{subscriber: self()})
      :ok = GenServer.call(pid, {:subscribe, subscriber_pid})

      receive do
        state ->
          assert state[:confirmations_count] == nil

          assert GenServer.stop(subscriber_pid) == :ok
          assert GenServer.stop(pid) == :ok
      end
    end
  end
end
