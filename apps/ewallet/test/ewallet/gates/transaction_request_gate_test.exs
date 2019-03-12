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

defmodule EWallet.TransactionRequestGateTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.TransactionRequestGate

  alias EWalletDB.{
    Account,
    AccountUser,
    Token,
    TransactionRequest,
    User,
    Wallet,
    Membership
  }

  alias ActivityLogger.System

  setup do
    {:ok, user} = :user |> params_for() |> User.insert()
    {:ok, account} = :account |> params_for() |> Account.insert()
    token = insert(:token)
    user_wallet = User.get_primary_wallet(user)
    account_wallet = Account.get_primary_wallet(account)

    %{
      user: user,
      token: token,
      user_wallet: user_wallet,
      account_wallet: account_wallet,
      account: account
    }
  end

  describe "create/1 with account_id" do
    test "receives an 'unauthorized' error when account_id is nil and no address", meta do
      res =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "account_id" => nil,
          "originator" => %System{}
        })

      assert res == {:error, :unauthorized}
    end

    test "receives an 'unauthorized' error when account_id is invalid and no address", meta do
      res =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "account_id" => "fake",
          "originator" => %System{}
        })

      assert res == {:error, :unauthorized}
    end

    test "receives an 'unauthorized' error when account_id is valid and address is nil", meta do
      res =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "account_id" => "fake",
          "address" => nil,
          "originator" => %System{}
        })

      assert res == {:error, :unauthorized}
    end

    test "succeed when account_id is valid and no address", meta do
      admin = insert(:admin)
      {:ok, _} = Membership.assign(admin, meta.account, "admin", %System{})

      {res, request} =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "account_id" => meta.account.id,
          "creator" => %{admin_user: admin},
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionRequest{} = request
    end

    test "succeed when account_id and address are valid", meta do
      admin = insert(:admin)
      {:ok, _} = Membership.assign(admin, meta.account, "admin", %System{})

      {:ok, request} =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "account_id" => meta.account.id,
          "address" => meta.account_wallet.address,
          "creator" => %{admin_user: admin},
          "originator" => %System{}
        })

      assert %TransactionRequest{} = request
      assert request.status == "valid"
    end

    test "receives an 'unauthorized' error when account_id is valid address is invalid", meta do
      res =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "account_id" => meta.account.id,
          "address" => "fake-0000-0000-0000",
          "originator" => %System{}
        })

      assert res == {:error, :unauthorized}
    end

    test "succeed when account_id, user and address are valid", meta do
      {:ok, _} = AccountUser.link(meta.account.uuid, meta.user.uuid, %System{})
      admin = insert(:admin)
      {:ok, _} = Membership.assign(admin, meta.account, "admin", %System{})

      {res, request} =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "account_id" => meta.account.id,
          "provider_user_id" => meta.user.provider_user_id,
          "address" => meta.user_wallet.address,
          "creator" => %{admin_user: admin},
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionRequest{} = request
      assert request.status == "valid"
      assert request.account_uuid == meta.account.uuid
      assert request.user_uuid == meta.user.uuid
      assert request.wallet_address == meta.user_wallet.address
    end

    test "receives an 'unauthorized' error when account_id and user are valid and address is invalid",
         meta do
      res =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "account_id" => meta.account.id,
          "provider_user_id" => meta.user.provider_user_id,
          "address" => meta.account_wallet.address,
          "originator" => %System{}
        })

      assert res == {:error, :unauthorized}
    end

    test "receives an 'unauthorized' error when account_id is valid and an address that does not belong to the account",
         meta do
      res =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "account_id" => meta.account.id,
          "address" => meta.user_wallet.address,
          "originator" => %System{}
        })

      assert res == {:error, :unauthorized}
    end
  end

  describe "create/1 with provider_user_id" do
    test "receives an 'unauthorized' error when provider_user_id is nil and no address", meta do
      res =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "provider_user_id" => nil,
          "originator" => %System{}
        })

      assert res == {:error, :unauthorized}
    end

    test "receives an 'unauthorized' error when provider_user_id is invalid and no address",
         meta do
      res =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "provider_user_id" => "fake",
          "originator" => %System{}
        })

      assert res == {:error, :unauthorized}
    end

    test "succeed when provider_user_id is valid and no address", meta do
      {:ok, _} = AccountUser.link(meta.account.uuid, meta.user.uuid, %System{})

      {res, request} =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "provider_user_id" => meta.user.provider_user_id,
          "creator" => %{end_user: meta.user},
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionRequest{} = request
    end

    test "succeed when provider_user_id and address are valid", meta do
      {res, request} =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "provider_user_id" => meta.user.provider_user_id,
          "address" => meta.user_wallet.address,
          "creator" => %{end_user: meta.user},
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionRequest{} = request
    end

    test "receives an 'unauthorized' error when provider_user_id is valid and address is invalid",
         meta do
      res =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "provider_user_id" => meta.user.provider_user_id,
          "address" => "fake-0000-0000-0000",
          "originator" => %System{}
        })

      assert res == {:error, :unauthorized}
    end

    test "receives an 'unauthorized' error when provider_user_id is valid and an address that does not belong to the user",
         meta do
      res =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "provider_user_id" => meta.user.provider_user_id,
          "address" => meta.account_wallet.address,
          "originator" => %System{}
        })

      assert res == {:error, :unauthorized}
    end
  end

  describe "create/1 with address" do
    test "receives an 'unauthorized' error when address is nil", meta do
      res =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => nil,
          "originator" => %System{}
        })

      assert res == {:error, :unauthorized}
    end

    test "succeed when address is valid", meta do
      {res, request} =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => meta.user_wallet.address,
          "creator" => %{end_user: meta.user},
          "originator" => %System{}
        })

      assert res == :ok
      assert %TransactionRequest{} = request
    end

    test "receives an 'unauthorized' error when address is invalid", meta do
      res =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => "fake-0000-0000-0000",
          "creator" => %{account: meta.account},
          "originator" => %System{}
        })

      assert res == {:error, :unauthorized}
    end
  end

  describe "create/1 with invalid parameters" do
    test "receives an 'invalid_parameter' error parameters are invalid", meta do
      res =
        TransactionRequestGate.create(%{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "originator" => %System{}
        })

      assert res == {:error, :invalid_parameter}
    end
  end

  describe "create/2 with %User{}" do
    test "creates a transaction request with all the params", meta do
      {:ok, _} = AccountUser.link(meta.account.uuid, meta.user.uuid, %System{})

      {:ok, request} =
        TransactionRequestGate.create(meta.user, %{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "address" => meta.user_wallet.address,
          "creator" => %{account: meta.account},
          "originator" => %System{}
        })

      assert %TransactionRequest{} = request
      assert request.id != nil
      assert request.type == "receive"
      assert request.token_uuid == meta.token.uuid
      assert request.correlation_id == "123"
      assert request.amount == 1_000
      assert request.wallet_address == meta.user_wallet.address
    end

    test "receives an invalid changeset error when the type is invalid", meta do
      {:error, changeset} =
        TransactionRequestGate.create(meta.user, %{
          "type" => "fake",
          "token_id" => meta.token.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => meta.user_wallet.address,
          "creator" => %{end_user: meta.user},
          "originator" => %System{}
        })

      assert changeset.errors == [type: {"is invalid", [validation: :inclusion]}]
    end

    test "receives a 'unauthorized' error when the address is invalid", meta do
      {:error, error} =
        TransactionRequestGate.create(meta.user, %{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => "fake-0000-0000-0000",
          "originator" => %System{}
        })

      assert error == :unauthorized
    end

    test "receives an 'unauthorized' error when the address does not belong to the user",
         meta do
      wallet = insert(:wallet)

      {:error, error} =
        TransactionRequestGate.create(meta.user, %{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => nil,
          "amount" => nil,
          "address" => wallet.address,
          "originator" => %System{}
        })

      assert error == :unauthorized
    end

    test "receives an 'unauthorized' error when the token ID is not found", meta do
      res =
        TransactionRequestGate.create(meta.user, %{
          "type" => "receive",
          "token_id" => "fake",
          "correlation_id" => nil,
          "amount" => nil,
          "address" => nil,
          "originator" => %System{}
        })

      assert res == {:error, :unauthorized}
    end
  end

  describe "create/2 with %Wallet{}" do
    test "creates a transaction request with all the params", meta do
      t0 = NaiveDateTime.utc_now()
      expiration = t0 |> NaiveDateTime.add(60_000, :millisecond)

      {:ok, request} =
        TransactionRequestGate.create(meta.user_wallet, %{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => "123",
          "amount" => 1_000,
          "allow_amount_override" => false,
          "require_confirmation" => true,
          "consumption_lifetime" => 60_000,
          "metadata" => %{two: "two"},
          "encrypted_metadata" => %{one: "one"},
          "expiration_date" => expiration,
          "expiration_reason" => "test",
          "expired_at" => "something",
          "max_consumptions" => 3,
          "creator" => %{end_user: meta.user},
          "originator" => %System{}
        })

      assert %TransactionRequest{} = request
      assert request.id != nil
      assert request.type == "receive"
      assert request.token_uuid == meta.token.uuid
      assert request.correlation_id == "123"
      assert request.amount == 1_000
      assert request.wallet_address == meta.user_wallet.address

      assert request.allow_amount_override == false
      assert request.require_confirmation == true
      assert request.consumption_lifetime == 60_000
      assert request.metadata == %{"two" => "two"}
      assert request.encrypted_metadata == %{"one" => "one"}
      assert request.expiration_date == expiration
      assert request.expiration_reason == nil
      assert request.expired_at == nil
      assert request.max_consumptions == 3
    end

    test "creates a transaction request with only type and token_id", meta do
      {:ok, request} =
        TransactionRequestGate.create(meta.user_wallet, %{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => nil,
          "amount" => nil,
          "creator" => %{end_user: meta.user},
          "originator" => %System{}
        })

      assert %TransactionRequest{} = request
    end

    test "receives an error when the token is disabled", meta do
      {:ok, token} =
        Token.enable_or_disable(meta.token, %{
          enabled: false,
          originator: %System{}
        })

      {:error, code} =
        TransactionRequestGate.create(meta.user_wallet, %{
          "type" => "receive",
          "token_id" => token.id,
          "correlation_id" => nil,
          "amount" => nil,
          "creator" => %{end_user: meta.user},
          "originator" => %System{}
        })

      assert code == :token_is_disabled
    end

    test "receives an error when the wallet is disabled", meta do
      {:ok, wallet} =
        Wallet.insert_secondary_or_burn(%{
          "account_uuid" => meta.account.uuid,
          "name" => "MySecondary",
          "identifier" => "secondary",
          "originator" => %System{}
        })

      {:ok, wallet} =
        Wallet.enable_or_disable(wallet, %{
          enabled: false,
          originator: %System{}
        })

      {:error, code} =
        TransactionRequestGate.create(wallet, %{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => nil,
          "amount" => nil,
          "creator" => %{end_user: meta.user},
          "originator" => %System{}
        })

      assert code == :wallet_is_disabled
    end

    test "receives an invalid changeset error when the type is invalid", meta do
      {:error, changeset} =
        TransactionRequestGate.create(meta.user_wallet, %{
          "type" => "fake",
          "token_id" => meta.token.id,
          "correlation_id" => nil,
          "amount" => nil,
          "creator" => %{end_user: meta.user},
          "originator" => %System{}
        })

      assert changeset.errors == [type: {"is invalid", [validation: :inclusion]}]
    end

    test "receives a 'invalid_parameter' error when the wallet is nil", meta do
      {:error, error} =
        TransactionRequestGate.create(nil, %{
          "type" => "receive",
          "token_id" => meta.token.id,
          "correlation_id" => nil,
          "amount" => nil,
          "originator" => %System{}
        })

      assert error == :invalid_parameter
    end

    test "receives an 'unauthorized' error when the token ID is not found", meta do
      res =
        TransactionRequestGate.create(meta.user_wallet, %{
          "type" => "receive",
          "token_id" => "fake",
          "correlation_id" => nil,
          "amount" => nil,
          "creator" => %{end_user: meta.user},
          "originator" => %System{}
        })

      assert res == {:error, :unauthorized}
    end
  end

  describe "expiration_from_lifetime/1" do
    test "returns nil if not require_confirmation" do
      request = insert(:transaction_request, require_confirmation: false)
      date = TransactionRequest.expiration_from_lifetime(request)
      assert date == nil
    end

    test "returns nil if no consumption lifetime" do
      request =
        insert(:transaction_request, require_confirmation: true, consumption_lifetime: nil)

      date = TransactionRequest.expiration_from_lifetime(request)
      assert date == nil
    end

    test "returns nil if consumption lifetime is equal to 0" do
      request = insert(:transaction_request, require_confirmation: true, consumption_lifetime: 0)
      date = TransactionRequest.expiration_from_lifetime(request)
      assert date == nil
    end

    test "returns the expiration date based on consumption_lifetime" do
      now = NaiveDateTime.utc_now()

      request =
        insert(
          :transaction_request,
          require_confirmation: true,
          consumption_lifetime: 1_000
        )

      date = TransactionRequest.expiration_from_lifetime(request)
      assert NaiveDateTime.compare(date, now) == :gt
    end
  end

  describe "expire_if_past_expiration_date/2" do
    test "does nothing if expiration date is not set" do
      request = insert(:transaction_request, expiration_date: nil)
      {res, request} = TransactionRequestGate.expire_if_past_expiration_date(request, %System{})
      assert res == :ok
      assert %TransactionRequest{} = request
      assert TransactionRequest.valid?(request) == true
    end

    test "does nothing if expiration date is not past" do
      future_date = NaiveDateTime.add(NaiveDateTime.utc_now(), 60, :second)
      request = insert(:transaction_request, expiration_date: future_date)
      {res, request} = TransactionRequestGate.expire_if_past_expiration_date(request, %System{})
      assert res == :ok
      assert %TransactionRequest{} = request
      assert TransactionRequest.valid?(request) == true
    end

    test "expires the request if expiration date is past" do
      past_date = NaiveDateTime.add(NaiveDateTime.utc_now(), -60, :second)
      request = insert(:transaction_request, expiration_date: past_date)
      {res, error} = TransactionRequestGate.expire_if_past_expiration_date(request, %System{})
      request = TransactionRequest.get(request.id)
      assert res == :error
      assert error == :expired_transaction_request
      assert TransactionRequest.valid?(request) == false
      assert TransactionRequest.expired?(request) == true
    end
  end

  describe "expire_if_max_consumption/2" do
    test "touches the request if max_consumptions is equal to nil" do
      request = insert(:transaction_request, max_consumptions: nil)
      {res, updated_request} = TransactionRequest.expire_if_max_consumption(request, %System{})
      assert res == :ok
      assert %TransactionRequest{} = updated_request
      assert TransactionRequest.valid?(updated_request) == true
      assert NaiveDateTime.compare(updated_request.updated_at, request.updated_at) == :gt
    end

    test "touches the request if max_consumptions is equal to 0" do
      request = insert(:transaction_request, max_consumptions: 0)
      {res, updated_request} = TransactionRequest.expire_if_max_consumption(request, %System{})
      assert res == :ok
      assert %TransactionRequest{} = updated_request
      assert TransactionRequest.valid?(updated_request) == true
      assert NaiveDateTime.compare(updated_request.updated_at, request.updated_at) == :gt
    end

    test "touches the request if max_consumptions has not been reached" do
      request = insert(:transaction_request, max_consumptions: 3)
      {res, updated_request} = TransactionRequest.expire_if_max_consumption(request, %System{})
      assert res == :ok
      assert %TransactionRequest{} = updated_request
      assert TransactionRequest.valid?(updated_request) == true
      assert NaiveDateTime.compare(updated_request.updated_at, request.updated_at) == :gt
    end

    test "expires the request if max_consumptions has been reached" do
      request = insert(:transaction_request, max_consumptions: 2)

      _consumption =
        insert(
          :transaction_consumption,
          transaction_request_uuid: request.uuid,
          status: "confirmed"
        )

      _consumption =
        insert(
          :transaction_consumption,
          transaction_request_uuid: request.uuid,
          status: "confirmed"
        )

      {res, updated_request} = TransactionRequest.expire_if_max_consumption(request, %System{})
      assert res == :ok
      assert %TransactionRequest{} = updated_request
      assert updated_request.expired_at != nil
      assert updated_request.expiration_reason == "max_consumptions_reached"
      assert TransactionRequest.valid?(updated_request) == false
      assert TransactionRequest.expired?(updated_request) == true
    end
  end
end
