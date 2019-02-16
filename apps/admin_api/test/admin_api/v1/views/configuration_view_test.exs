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

defmodule AdminAPI.V1.ConfigurationViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.V1.ConfigurationView
  alias EWallet.Web.Paginator
  alias EWallet.Web.V1.ConfigurationSerializer
  alias EWalletConfig.Factory, as: ConfigFactory

  setup do
    :ok = Sandbox.checkout(EWalletConfig.Repo)
  end

  describe "render/2" do
    test "renders settings.json with correct response structure" do
      stored_setting_1 = ConfigFactory.insert(:stored_setting)
      stored_setting_2 = ConfigFactory.insert(:stored_setting)

      paginator = %Paginator{
        data: [stored_setting_1, stored_setting_2],
        pagination: %{
          per_page: 10,
          current_page: 1,
          is_first_page: true,
          is_last_page: false
        }
      }

      expected = %{
        version: @expected_version,
        success: true,
        data: ConfigurationSerializer.serialize(paginator)
      }

      assert ConfigurationView.render("settings.json", %{settings: paginator}) == expected
    end

    test "renders settings_with_errors.json with correct response structure" do
      stored_setting_1 = ConfigFactory.insert(:stored_setting)
      stored_setting_2 = ConfigFactory.insert(:stored_setting)

      settings = [
        {stored_setting_1.key, {:ok, stored_setting_1}},
        {stored_setting_2.key, {:ok, stored_setting_2}}
      ]

      expected = %{
        version: @expected_version,
        success: true,
        data: ConfigurationSerializer.serialize_with_errors(settings)
      }

      assert ConfigurationView.render("settings_with_errors.json", %{settings: settings}) ==
               expected
    end
  end
end
