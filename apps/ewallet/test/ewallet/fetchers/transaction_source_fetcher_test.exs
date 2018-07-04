defmodule EWallet.TransactionSourceFetcherTest do
  use EWallet.LocalLedgerCase, async: true
  alias EWallet.TransactionSourceFetcher
  alias EWalletDB.{Account, User}

  describe "fetch_from/1 with invalid params" do
    test "returns error when sending both account_id and user_id" do
      {res, code, desc} =
        TransactionSourceFetcher.fetch_from(%{
          "from_account_id" => "account",
          "from_user_id" => "user"
        })

      assert res == :error
      assert code == :invalid_parameter
      assert desc == "'from_account_id' and 'from_user_id' are exclusive"
    end

    test "returns error when sending both account_id and provider_user_id" do
      {res, code, desc} =
        TransactionSourceFetcher.fetch_from(%{
          "from_account_id" => "account",
          "from_provider_user_id" => "user"
        })

      assert res == :error
      assert code == :invalid_parameter
      assert desc == "'from_account_id' and 'from_provider_user_id' are exclusive"
    end

    test "returns error when sending both user_id and provider_user_id" do
      {res, code, desc} =
        TransactionSourceFetcher.fetch_from(%{
          "from_user_id" => "user",
          "from_provider_user_id" => "user"
        })

      assert res == :error
      assert code == :invalid_parameter
      assert desc == "'from_user_id' and 'from_provider_user_id' are exclusive"
    end

    test "returns error whn invalid params" do
      {res, code} = TransactionSourceFetcher.fetch_from(%{})

      assert res == :error
      assert code == :invalid_parameter
    end
  end

  describe "fetch_from/1 with account_id" do
    test "returns account and address when given valid account_id and address" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)

      {res, data} =
        TransactionSourceFetcher.fetch_from(%{
          "from_account_id" => account.id,
          "from_address" => wallet.address
        })

      assert res == :ok

      assert data == %{
               from_account_uuid: account.uuid,
               from_wallet_address: wallet.address
             }
    end

    test "returns account and primary address when given valid account_id and nil address" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)

      {res, data} =
        TransactionSourceFetcher.fetch_from(%{
          "from_account_id" => account.id,
          "from_address" => nil
        })

      assert res == :ok

      assert data == %{
               from_account_uuid: account.uuid,
               from_wallet_address: wallet.address
             }
    end

    test "returns error when giving address that does not belong to account" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = insert(:wallet)

      {res, data} =
        TransactionSourceFetcher.fetch_from(%{
          "from_account_id" => account.id,
          "from_address" => wallet.address
        })

      assert res == :error
      assert data == :account_from_address_mismatch
    end

    test "returns error when account does not exist" do
      wallet = insert(:wallet)

      {res, data} =
        TransactionSourceFetcher.fetch_from(%{
          "from_account_id" => "fake",
          "from_address" => wallet.address
        })

      assert res == :error
      assert data == :account_id_not_found
    end

    test "returns error when address does not exist" do
      {:ok, account} = :account |> params_for() |> Account.insert()

      {res, data} =
        TransactionSourceFetcher.fetch_from(%{
          "from_account_id" => account.id,
          "from_address" => "fake"
        })

      assert res == :error
      assert data == :from_address_not_found
    end
  end

  describe "fetch_from/1 with user_id" do
    test "returns user and address when given valid user_id and address" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      {res, data} =
        TransactionSourceFetcher.fetch_from(%{
          "from_user_id" => user.id,
          "from_address" => wallet.address
        })

      assert res == :ok

      assert data == %{
               from_user_uuid: user.uuid,
               from_wallet_address: wallet.address
             }
    end

    test "returns user and primary address when given valid user_id and nil address" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      {res, data} =
        TransactionSourceFetcher.fetch_from(%{
          "from_user_id" => user.id,
          "from_address" => nil
        })

      assert res == :ok

      assert data == %{
               from_user_uuid: user.uuid,
               from_wallet_address: wallet.address
             }
    end

    test "returns error when giving address that does not belong to user" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      {res, data} =
        TransactionSourceFetcher.fetch_from(%{
          "from_user_id" => user.id,
          "from_address" => nil
        })

      assert res == :ok

      assert data == %{
               from_user_uuid: user.uuid,
               from_wallet_address: wallet.address
             }
    end

    test "returns error when user does not exist" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      {res, data} =
        TransactionSourceFetcher.fetch_from(%{
          "from_user_id" => "fake",
          "from_address" => wallet.address
        })

      assert res == :error
      assert data == :user_id_not_found
    end

    test "returns error when address does not exist" do
      {:ok, user} = :user |> params_for() |> User.insert()

      {res, data} =
        TransactionSourceFetcher.fetch_from(%{
          "from_user_id" => user.id,
          "from_address" => "fake"
        })

      assert res == :error
      assert data == :from_address_not_found
    end
  end

  describe "fetch_from/1 with provider_user_id" do
    test "returns user and address when given valid provider_user_id and address" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      {res, data} =
        TransactionSourceFetcher.fetch_from(%{
          "from_provider_user_id" => user.provider_user_id,
          "from_address" => wallet.address
        })

      assert res == :ok

      assert data == %{
               from_user_uuid: user.uuid,
               from_wallet_address: wallet.address
             }
    end

    test "returns user and primary address when given valid provider_user_id and nil address" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      {res, data} =
        TransactionSourceFetcher.fetch_from(%{
          "from_provider_user_id" => user.provider_user_id,
          "from_address" => nil
        })

      assert res == :ok

      assert data == %{
               from_user_uuid: user.uuid,
               from_wallet_address: wallet.address
             }
    end

    test "returns error when giving address that does not belong to user" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      {res, data} =
        TransactionSourceFetcher.fetch_from(%{
          "from_provider_user_id" => user.provider_user_id,
          "from_address" => nil
        })

      assert res == :ok

      assert data == %{
               from_user_uuid: user.uuid,
               from_wallet_address: wallet.address
             }
    end

    test "returns error when user does not exist" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      {res, data} =
        TransactionSourceFetcher.fetch_from(%{
          "from_provider_user_id" => "fake",
          "from_address" => wallet.address
        })

      assert res == :error
      assert data == :provider_user_id_not_found
    end

    test "returns error when address does not exist" do
      {:ok, user} = :user |> params_for() |> User.insert()

      {res, data} =
        TransactionSourceFetcher.fetch_from(%{
          "from_provider_user_id" => user.provider_user_id,
          "from_address" => "fake"
        })

      assert res == :error
      assert data == :from_address_not_found
    end
  end

  describe "fetch_from/1 with address" do
    test "returns error when wallet is not found" do
      {res, data} =
        TransactionSourceFetcher.fetch_from(%{
          "from_address" => "fake"
        })

      assert res == :error
      assert data == :from_address_not_found
    end

    test "returns user and wallet when the wallet belongs to a user" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      {res, data} =
        TransactionSourceFetcher.fetch_from(%{
          "from_address" => wallet.address
        })

      assert res == :ok

      assert data == %{
               from_user_uuid: user.uuid,
               from_wallet_address: wallet.address
             }
    end

    test "returns account and wallet when the wallet belongs to an account" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)

      {res, data} =
        TransactionSourceFetcher.fetch_from(%{
          "from_address" => wallet.address
        })

      assert res == :ok

      assert data == %{
               from_account_uuid: account.uuid,
               from_wallet_address: wallet.address
             }
    end
  end

  describe "fetch_to/1" do
    test "returns user and address when given valid provider_user_id and address" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      {res, data} =
        TransactionSourceFetcher.fetch_to(%{
          "to_provider_user_id" => user.provider_user_id,
          "to_address" => wallet.address
        })

      assert res == :ok

      assert data == %{
               to_user_uuid: user.uuid,
               to_wallet_address: wallet.address
             }
    end

    test "returns user and primary address when given valid provider_user_id and nil address" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      {res, data} =
        TransactionSourceFetcher.fetch_to(%{
          "to_provider_user_id" => user.provider_user_id,
          "to_address" => nil
        })

      assert res == :ok

      assert data == %{
               to_user_uuid: user.uuid,
               to_wallet_address: wallet.address
             }
    end

    test "returns error when giving address that does not belong to user" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      {res, data} =
        TransactionSourceFetcher.fetch_to(%{
          "to_provider_user_id" => user.provider_user_id,
          "to_address" => nil
        })

      assert res == :ok

      assert data == %{
               to_user_uuid: user.uuid,
               to_wallet_address: wallet.address
             }
    end

    test "returns error when user does not exist" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      {res, data} =
        TransactionSourceFetcher.fetch_to(%{
          "to_provider_user_id" => "fake",
          "to_address" => wallet.address
        })

      assert res == :error
      assert data == :provider_user_id_not_found
    end

    test "returns error when address does not exist" do
      {:ok, user} = :user |> params_for() |> User.insert()

      {res, data} =
        TransactionSourceFetcher.fetch_to(%{
          "to_provider_user_id" => user.provider_user_id,
          "to_address" => "fake"
        })

      assert res == :error
      assert data == :to_address_not_found
    end
  end

  describe "fetch_to/1 with address" do
    test "returns error when wallet is not found" do
      {res, data} =
        TransactionSourceFetcher.fetch_to(%{
          "to_address" => "fake"
        })

      assert res == :error
      assert data == :to_address_not_found
    end

    test "returns user and wallet when the wallet belongs to a user" do
      {:ok, user} = :user |> params_for() |> User.insert()
      wallet = User.get_primary_wallet(user)

      {res, data} =
        TransactionSourceFetcher.fetch_to(%{
          "to_address" => wallet.address
        })

      assert res == :ok

      assert data == %{
               to_user_uuid: user.uuid,
               to_wallet_address: wallet.address
             }
    end

    test "returns account and wallet when the wallet belongs to an account" do
      {:ok, account} = :account |> params_for() |> Account.insert()
      wallet = Account.get_primary_wallet(account)

      {res, data} =
        TransactionSourceFetcher.fetch_to(%{
          "to_address" => wallet.address
        })

      assert res == :ok

      assert data == %{
               to_account_uuid: account.uuid,
               to_wallet_address: wallet.address
             }
    end
  end
end
