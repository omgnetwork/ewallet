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

defmodule AdminAPI.V1.AccountMembershipViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.AccountMembershipView
  alias EWallet.Web.V1.MembershipSerializer
  alias EWalletDB.Repo

  describe "AccountMembershipView.render/2" do
    test "renders memberships.json with users response" do
      membership1 = :membership |> insert() |> Repo.preload([:user, :role])
      membership2 = :membership |> insert() |> Repo.preload([:user, :role])
      memberships = [membership1, membership2]

      expected = %{
        version: @expected_version,
        success: true,
        data: %{
          object: "list",
          data: [
            MembershipSerializer.serialize(membership1),
            MembershipSerializer.serialize(membership2)
          ]
        }
      }

      assert AccountMembershipView.render("memberships.json", %{memberships: memberships}) ==
               expected
    end

    test "renders empty.json correctly" do
      assert AccountMembershipView.render("empty.json", %{success: true}) ==
               %{
                 version: @expected_version,
                 success: true,
                 data: %{}
               }
    end
  end
end
