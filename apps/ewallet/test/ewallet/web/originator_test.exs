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

defmodule EWallet.Web.OriginatorTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.Web.Originator
  alias EWalletDB.{Account, Key, Repo, User}
  alias Plug.Conn

  setup do
    ActivityLogger.configure(%{
      EWalletDB.User => %{type: "user", identifier: :id}
    })

    :ok
  end

  describe "extract/1" do
    test "returns the key when key is assigned in the Conn" do
      conn = %Conn{assigns: %{key: %Key{access_key: "1234"}}}
      assert Originator.extract(conn.assigns) == %Key{access_key: "1234"}
    end

    test "returns the admin_user when admin_user is assigned in the Conn" do
      conn = %Conn{assigns: %{admin_user: %User{is_admin: true}}}
      assert Originator.extract(conn.assigns) == %User{is_admin: true}
    end

    test "returns the end_user when end_user is assigned in the Conn" do
      conn = %Conn{assigns: %{end_user: %User{is_admin: false}}}
      assert Originator.extract(conn.assigns) == %User{is_admin: false}
    end
  end

  describe "set_in_attrs/3" do
    test "puts the originator into the given attributes" do
      conn = %Conn{assigns: %{key: %Key{access_key: "1234"}}}
      attrs = %{title: "some_title"}
      attrs = Originator.set_in_attrs(attrs, conn.assigns)

      assert attrs["originator"] == %Key{access_key: "1234"}
    end
  end

  describe "get_initial_originator/1" do
    test "returns the originator that inserted the record" do
      insert_user = insert(:user)
      update_user = insert(:user)

      {:ok, inserted} =
        :account
        |> params_for(originator: insert_user)
        |> Account.insert()

      {:ok, updated} =
        Account.update(inserted, %{
          name: "updated_name",
          originator: update_user
        })

      assert Originator.get_initial_originator(updated, Repo).uuid == insert_user.uuid
    end
  end
end
