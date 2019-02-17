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

defmodule EWallet.UserFetcherTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.UserFetcher
  alias EWalletDB.User

  setup do
    {:ok, user} = :user |> params_for() |> User.insert()
    %{user: user}
  end

  describe "get/1" do
    test "retrieves a user from its id", meta do
      {:ok, user} = UserFetcher.fetch(%{"user_id" => meta.user.id})
      assert user.uuid == meta.user.uuid
    end

    test "retrieves a user from its provider_user_id", meta do
      {:ok, user} = UserFetcher.fetch(%{"provider_user_id" => meta.user.provider_user_id})
      assert user.uuid == meta.user.uuid
    end

    test "Raise user_id_not_found if the user_id doesn't exist" do
      {:error, error} = UserFetcher.fetch(%{"user_id" => "fake"})
      assert error == :user_id_not_found
    end

    test "Raise provider_user_id_not_found if the user_id doesn't exist" do
      {:error, error} = UserFetcher.fetch(%{"provider_user_id" => "fake"})
      assert error == :provider_user_id_not_found
    end

    test "Raise invalid_parameter if no user_id or provider_user_id" do
      {:error, error} = UserFetcher.fetch(%{})
      assert error == :invalid_parameter
    end
  end
end
