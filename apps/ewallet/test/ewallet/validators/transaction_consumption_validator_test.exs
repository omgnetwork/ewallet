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

defmodule EWallet.TransactionConsumptionValidatorTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.{TestEndpoint, TransactionConsumptionValidator}

  alias EWalletDB.{
    Account,
    Repo,
    TransactionConsumption,
    Membership,
    TransactionRequest,
    GlobalRole,
    User
  }

  alias ActivityLogger.System

  def creator do
    insert(:admin, global_role: GlobalRole.super_admin())
  end

  describe "validate_before_consumption/3" do
    test "expires a transaction request if past expiration date" do
      now = NaiveDateTime.utc_now()

      request =
        insert(:transaction_request, expiration_date: NaiveDateTime.add(now, -60, :second))

      wallet = request.wallet

      {:error, error} =
        TransactionConsumptionValidator.validate_before_consumption(request, wallet, %{
          "creator" => creator()
        })

      assert error == :expired_transaction_request
    end

    test "returns expiration reason if transaction request has expired" do
      {:ok, request} = :transaction_request |> insert() |> TransactionRequest.expire(%System{})
      wallet = request.wallet

      {:error, error} =
        TransactionConsumptionValidator.validate_before_consumption(request, wallet, %{
          "creator" => creator()
        })

      assert error == :expired_transaction_request
    end

    test "returns unauthorized_amount_override amount when attempting to override illegally" do
      request = insert(:transaction_request, allow_amount_override: false)
      wallet = request.wallet

      {:error, error} =
        TransactionConsumptionValidator.validate_before_consumption(request, wallet, %{
          "amount" => 100,
          "creator" => creator()
        })

      assert error == :unauthorized_amount_override
    end

    test "returns the request, token and amount" do
      request = insert(:transaction_request)
      wallet = request.wallet

      {:ok, request, token, amount} =
        TransactionConsumptionValidator.validate_before_consumption(request, wallet, %{
          "creator" => creator()
        })

      assert request.status == "valid"
      assert token.uuid == request.token_uuid
      assert amount == nil
    end
  end

  describe "validate_before_confirmation/2" do
    setup do
      {:ok, pid} = TestEndpoint.start_link()

      on_exit(fn ->
        ref = Process.monitor(pid)
        assert_receive {:DOWN, ^ref, _, _, _}
      end)

      :ok
    end

    test "returns unauthorized if the request is not owned by user" do
      {:ok, user} = :user |> params_for() |> User.insert()
      consumption = :transaction_consumption |> insert() |> Repo.preload([:transaction_request])

      {status, res} =
        TransactionConsumptionValidator.validate_before_confirmation(consumption, %{
          end_user: user
        })

      assert status == :error
      assert %{authorized: false} = res
    end

    test "returns unauthorized if the request is not owned by account" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      admin = insert(:admin)
      {:ok, _} = Membership.assign(admin, account, "admin", %System{})

      consumption = :transaction_consumption |> insert() |> Repo.preload([:transaction_request])

      {status, res} =
        TransactionConsumptionValidator.validate_before_confirmation(consumption, %{
          admin_user: admin
        })

      assert status == :error
      assert %{authorized: false} = res
    end

    test "expires request if past expiration date" do
      now = NaiveDateTime.utc_now()
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      request =
        insert(
          :transaction_request,
          expiration_date: NaiveDateTime.add(now, -60, :second),
          account_uuid: nil,
          user_uuid: user.uuid,
          wallet: wallet
        )

      consumption =
        :transaction_consumption
        |> insert(transaction_request_uuid: request.uuid)
        |> Repo.preload([:transaction_request])

      {status, res} =
        TransactionConsumptionValidator.validate_before_confirmation(consumption, %{
          end_user: user
        })

      assert status == :error
      assert res == :expired_transaction_request
    end

    test "returns expiration reason if expired request" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      request =
        insert(
          :transaction_request,
          status: "expired",
          expiration_reason: "max_consumptions_reached",
          account_uuid: nil,
          user_uuid: user.uuid,
          wallet: wallet
        )

      consumption =
        :transaction_consumption
        |> insert(transaction_request_uuid: request.uuid)
        |> Repo.preload([:transaction_request])

      {status, res} =
        TransactionConsumptionValidator.validate_before_confirmation(consumption, %{
          end_user: user
        })

      assert status == :error
      assert res == :max_consumptions_reached
    end

    test "returns max_consumptions_per_user_reached if the max has been reached" do
      {:ok, user_1} = :user |> params_for() |> User.insert()
      {:ok, user_2} = :user |> params_for() |> User.insert()
      wallet_1 = User.get_primary_wallet(user_1)
      wallet_2 = User.get_primary_wallet(user_2)

      request =
        insert(
          :transaction_request,
          max_consumptions_per_user: 1,
          account_uuid: nil,
          user_uuid: user_1.uuid,
          wallet: wallet_1
        )

      _consumption =
        :transaction_consumption
        |> insert(
          account_uuid: nil,
          user_uuid: user_2.uuid,
          wallet_address: wallet_2.address,
          transaction_request_uuid: request.uuid,
          status: "confirmed"
        )

      consumption =
        :transaction_consumption
        |> insert(
          account_uuid: nil,
          wallet_address: wallet_2.address,
          user_uuid: user_2.uuid,
          transaction_request_uuid: request.uuid
        )
        |> Repo.preload([:transaction_request, :wallet])

      {status, res} =
        TransactionConsumptionValidator.validate_before_confirmation(consumption, %{
          end_user: user_1
        })

      assert status == :error
      assert res == :max_consumptions_per_user_reached
    end

    test "expires consumption if past expiration" do
      now = NaiveDateTime.utc_now()
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      request =
        insert(:transaction_request, account_uuid: nil, user_uuid: user.uuid, wallet: wallet)

      consumption =
        :transaction_consumption
        |> insert(
          expiration_date: NaiveDateTime.add(now, -60, :second),
          transaction_request_uuid: request.uuid
        )
        |> Repo.preload([:transaction_request])

      {status, res} =
        TransactionConsumptionValidator.validate_before_confirmation(consumption, %{
          end_user: user
        })

      assert status == :error
      assert res == :expired_transaction_consumption
    end

    test "returns expired_transaction_consumption if the consumption has expired" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      request =
        insert(:transaction_request, account_uuid: nil, user_uuid: user.uuid, wallet: wallet)

      consumption =
        :transaction_consumption
        |> insert(status: "expired", transaction_request_uuid: request.uuid)
        |> Repo.preload([:transaction_request])

      {status, res} =
        TransactionConsumptionValidator.validate_before_confirmation(consumption, %{
          end_user: user
        })

      assert status == :error
      assert res == :expired_transaction_consumption
    end

    test "returns 'cancelled_transaction_consumption' if the consumption is cancelled" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      request =
        insert(:transaction_request, account_uuid: nil, user_uuid: user.uuid, wallet: wallet)

      consumption =
        :transaction_consumption
        |> insert(status: "cancelled", transaction_request_uuid: request.uuid)
        |> Repo.preload([:transaction_request])

      {status, res} =
        TransactionConsumptionValidator.validate_before_confirmation(consumption, %{
          end_user: user
        })

      assert status == :error
      assert res == :cancelled_transaction_consumption
    end

    test "returns the consumption if valid" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      request =
        insert(:transaction_request, account_uuid: nil, user_uuid: user.uuid, wallet: wallet)

      consumption =
        :transaction_consumption
        |> insert(transaction_request_uuid: request.uuid)
        |> Repo.preload([:transaction_request])

      {status, res} =
        TransactionConsumptionValidator.validate_before_confirmation(consumption, %{
          end_user: user
        })

      assert status == :ok
      assert %TransactionConsumption{} = res
      assert res.status == "pending"
    end
  end

  describe "get_and_validate_token/2" do
    test "returns the request's token if nil is passed" do
      request = insert(:transaction_request)

      {:ok, token} = TransactionConsumptionValidator.get_and_validate_token(request, nil)
      assert token.uuid == request.token_uuid
    end

    test "returns a token_not_found error if given not existing token" do
      request = insert(:transaction_request)

      {:error, code} = TransactionConsumptionValidator.get_and_validate_token(request, "fake")

      assert code == :token_not_found
    end

    test "returns a invalid_token_provided error if given a different token without pair" do
      request = insert(:transaction_request)
      token = insert(:token)

      {:error, code} = TransactionConsumptionValidator.get_and_validate_token(request, token.id)

      assert code == :exchange_pair_not_found
    end

    test "returns a invalid_token_provided error if given a different token with pair" do
      token_1 = insert(:token)
      token_2 = insert(:token)
      _pair = insert(:exchange_pair, from_token: token_1, to_token: token_2)
      request = insert(:transaction_request, token_uuid: token_1.uuid)

      {:error, code} = TransactionConsumptionValidator.get_and_validate_token(request, token_2.id)

      assert code == :exchange_pair_not_found
    end

    test "returns the specified token if valid" do
      request = :transaction_request |> insert() |> Repo.preload([:token])
      token = request.token

      {:ok, token} = TransactionConsumptionValidator.get_and_validate_token(request, token.id)

      assert token.uuid == request.token_uuid
    end
  end

  describe "validate_max_consumptions_per_user/2" do
    test "returns the wallet if max_consumptions_per_user is not set" do
      request = insert(:transaction_request)
      wallet = insert(:wallet)

      {status, res} =
        TransactionConsumptionValidator.validate_max_consumptions_per_user(request, wallet)

      assert status == :ok
      assert res == wallet
    end

    test "returns the wallet if the request is for an account" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)
      request = insert(:transaction_request, max_consumptions_per_user: 0)

      {status, res} =
        TransactionConsumptionValidator.validate_max_consumptions_per_user(request, wallet)

      assert status == :ok
      assert res == wallet
    end

    test "returns the wallet if the current number of active consumptions is lower
          than the max_consumptions_per_user" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)
      request = insert(:transaction_request, max_consumptions_per_user: 1)

      {status, res} =
        TransactionConsumptionValidator.validate_max_consumptions_per_user(request, wallet)

      assert status == :ok
      assert res == wallet
    end

    test "returns max_consumptions_per_user_reached when it has been reached" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)
      request = insert(:transaction_request, max_consumptions_per_user: 0)

      {status, res} =
        TransactionConsumptionValidator.validate_max_consumptions_per_user(request, wallet)

      assert status == :error
      assert res == :max_consumptions_per_user_reached
    end
  end
end
