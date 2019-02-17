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

defmodule EWallet.TransactionRequestSchedulerTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.TransactionRequestScheduler
  alias EWalletDB.TransactionRequest

  describe "expire_all/0" do
    test "expires all requests past their expiration date" do
      now = NaiveDateTime.utc_now()

      # t1 and t2 have expiration dates in the past
      t1 = insert(:transaction_request, expiration_date: NaiveDateTime.add(now, -60, :second))
      t2 = insert(:transaction_request, expiration_date: NaiveDateTime.add(now, -600, :second))
      t3 = insert(:transaction_request, expiration_date: NaiveDateTime.add(now, 600, :second))
      t4 = insert(:transaction_request, expiration_date: NaiveDateTime.add(now, 160, :second))

      # They are still valid since we haven't made them expired yet
      assert TransactionRequest.expired?(t1) == false
      assert TransactionRequest.expired?(t2) == false
      assert TransactionRequest.expired?(t3) == false
      assert TransactionRequest.expired?(t4) == false

      TransactionRequestScheduler.expire_all()

      # Reload all the records
      t1 = TransactionRequest.get(t1.id)
      t2 = TransactionRequest.get(t2.id)
      t3 = TransactionRequest.get(t3.id)
      t4 = TransactionRequest.get(t4.id)

      # Now t1 and t2 are expired
      assert TransactionRequest.expired?(t1) == true
      assert TransactionRequest.expired?(t2) == true
      assert TransactionRequest.expired?(t3) == false
      assert TransactionRequest.expired?(t4) == false
    end

    test "sets the expiration reason" do
      now = NaiveDateTime.utc_now()
      t = insert(:transaction_request, expiration_date: NaiveDateTime.add(now, -60, :second))
      TransactionRequestScheduler.expire_all()
      t = TransactionRequest.get(t.id)

      assert TransactionRequest.expired?(t) == true
      assert t.expired_at != nil
      assert t.expiration_reason == "expired_transaction_request"
    end
  end
end
