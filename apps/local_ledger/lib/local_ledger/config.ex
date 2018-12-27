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

defmodule LocalLedger.Config do
  @moduledoc """
  Provides a configuration function that are called during application startup.
  """

  def read_scheduler_config do
    case System.get_env("BALANCE_CACHING_FREQUENCY") do
      nil ->
        []

      frequency ->
        [
          cache_all_wallets: [
            schedule: frequency,
            task: {LocalLedger.Balance, :cache_all, []},
            run_strategy: {Quantum.RunStrategy.Random, :cluster}
          ]
        ]
    end
  end
end
