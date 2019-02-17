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

defmodule EWalletDB.Helpers.PreloaderTest do
  use EWalletDB.SchemaCase, async: true
  import EWalletDB.Factory
  alias Ecto.Association.NotLoaded
  alias EWalletDB.Helpers.Preloader
  alias EWalletDB.{Account, Membership, Role, User, Repo}

  setup do
    membership = insert(:membership)
    membership = Repo.get(Membership, membership.uuid)

    assert %NotLoaded{} = membership.user
    assert %NotLoaded{} = membership.role
    assert %NotLoaded{} = membership.account

    %{membership: membership}
  end

  describe "preload_option/2" do
    test "preloads only the fields specified in the :preload option", context do
      membership = Preloader.preload_option(context.membership, preload: [:role])

      assert %NotLoaded{} = membership.user
      assert %Role{} = membership.role
      assert %NotLoaded{} = membership.account
    end

    test "does nothing when :preload option is not given", context do
      membership = Preloader.preload_option(context.membership, [])

      assert %NotLoaded{} = membership.user
      assert %NotLoaded{} = membership.role
      assert %NotLoaded{} = membership.account
    end
  end

  describe "preload/2" do
    test "preloads the given associations", context do
      membership = Preloader.preload(context.membership, [:user, :account])

      assert %User{} = membership.user
      assert %NotLoaded{} = membership.role
      assert %Account{} = membership.account
    end
  end
end
