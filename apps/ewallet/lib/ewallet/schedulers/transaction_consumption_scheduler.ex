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

defmodule EWallet.TransactionConsumptionScheduler do
  @moduledoc """
  Scheduler containing logic for CRON tasks related to
  transaction consumptions.
  """
  alias EWallet.Web.V1.Event
  alias EWalletDB.TransactionConsumption

  @doc """
  Expires all transaction consumptions which are
  past their expiration dates and send a failed
  "transaction_consumption_finalized" event.
  """
  def expire_all do
    {_count, consumptions} = TransactionConsumption.expire_all()

    Enum.each(consumptions, fn consumption ->
      Event.dispatch(:transaction_consumption_finalized, %{consumption: consumption})
    end)
  end
end
