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

defmodule AdminAPI.V1.SettingsView do
  use AdminAPI, :view
  alias EWallet.Web.V1.{ResponseSerializer, SettingsSerializer}

  def render("settings.json", settings) do
    settings
    |> SettingsSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
