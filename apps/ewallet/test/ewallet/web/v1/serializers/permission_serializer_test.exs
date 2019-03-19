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

defmodule EWallet.Web.V1.PermissionSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWallet.Web.V1.PermissionSerializer

  @global_role_permissions %{
    "super_admin" => :global,
    "admin" => %{
      account_transactions: %{
        all: :accounts,
        create: :accounts
      }
    },
    "viewer" => %{
      account_transactions: %{
        all: :accounts,
        create: :none
      }
    }
  }

  @account_role_permissions %{
    "admin" => %{
      account_transactions: %{
        all: :accounts,
        create: :accounts
      }
    },
    "viewer" => %{
      account_transactions: %{
        all: :accounts
      }
    }
  }

  describe "serialize/1" do
    test "serializes permissions into V1 response format" do
      permissions = %{
        global_roles: @global_role_permissions,
        account_roles: @account_role_permissions
      }

      expected = %{
        object: "permissions",
        global_roles: @global_role_permissions,
        account_roles: @account_role_permissions
      }

      assert PermissionSerializer.serialize(permissions) == expected
    end
  end
end
