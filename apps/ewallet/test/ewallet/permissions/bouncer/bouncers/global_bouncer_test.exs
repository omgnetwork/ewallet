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

defmodule EWallet.GlobalBouncerTest do
  use ExUnit.Case, async: true
  alias EWallet.Bouncer.{GlobalBouncer, Permission, TestDispatchConfig}
  alias EWallet.{Bike, Helper}

  def permissions do
    %{
      "super_admin" => :global,
      "admin" => %{
        bike: %{all: :global, get: :accounts, create: :accounts, update: :accounts},
        account_permissions: true
      },
      "viewer" => %{
        bike: %{all: :global, get: :accounts, create: :none, update: :none},
        account_permissions: true
      },
      "end_user" => %{
        bike: %{all: :global, get: :self, create: :self, update: :self},
        account_permissions: false
      },
      "none" => %{
        account_permissions: true
      }
    }
  end

    # action = all
    # action = export
    # action = other

    # :global permission
    # :account permission
    #   allowed
    #   not allowed
    # :self
    #   allowed
    #   not allowed
    # other
    # check permission
    # check scope

  describe "bounce/1 with action = all" do
    test "with global permission (authorized)" do

      actor = %{global_role: "super_admin"}
      permission = %Permission{actor: actor, action: :all, type: :bike, schema: Bike}

      res = GlobalBouncer.bounce(permission, %{
        dispatch_config: TestDispatchConfig,
        global_permissions: permissions
      })

      assert res.global_authorized == true
      assert res.global_role == "super_admin"
      assert res.global_abilities == %{bikes: :global}
    end
  end
end
