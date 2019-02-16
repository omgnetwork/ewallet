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

defmodule EWalletConfig.Factory do
  @moduledoc """
  Factories used for testing.
  """
  use ExMachina.Ecto, repo: EWalletConfig.Repo
  alias ActivityLogger.System
  alias EWalletConfig.StoredSetting

  def stored_setting_factory do
    %StoredSetting{
      key: sequence("setting_key"),
      data: %{
        value: sequence("setting_value")
      },
      type: "string",
      description: sequence("Setting description"),
      options: nil,
      parent: nil,
      parent_value: nil,
      secret: false,
      position: sequence(""),
      originator: %System{}
    }
  end
end
