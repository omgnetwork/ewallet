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

defmodule EWallet.ForgetPasswordRequestSchedulerTest do
  use EWallet.DBCase, async: true
  import EWalletDB.Factory
  alias EWallet.ForgetPasswordRequestScheduler
  alias EWalletDB.{ForgetPasswordRequest, Repo}

  describe "expire_all/0" do
    test "expires all requests past their expiration date" do
      now = NaiveDateTime.utc_now()

      # f1 and f2 have expiration dates in the past
      f1 = insert(:forget_password_request, expires_at: NaiveDateTime.add(now, -60, :second))
      f2 = insert(:forget_password_request, expires_at: NaiveDateTime.add(now, -600, :second))
      f3 = insert(:forget_password_request, expires_at: NaiveDateTime.add(now, 600, :second))
      f4 = insert(:forget_password_request, expires_at: NaiveDateTime.add(now, 160, :second))

      # They are still valid since we haven't made them expired yet
      assert Repo.get(ForgetPasswordRequest, f1.uuid).enabled == true
      assert Repo.get(ForgetPasswordRequest, f2.uuid).enabled == true
      assert Repo.get(ForgetPasswordRequest, f3.uuid).enabled == true
      assert Repo.get(ForgetPasswordRequest, f4.uuid).enabled == true

      ForgetPasswordRequestScheduler.expire_all()

      # Now t1 and t2 are expired
      assert Repo.get(ForgetPasswordRequest, f1.uuid).enabled == false
      assert Repo.get(ForgetPasswordRequest, f2.uuid).enabled == false
      assert Repo.get(ForgetPasswordRequest, f3.uuid).enabled == true
      assert Repo.get(ForgetPasswordRequest, f4.uuid).enabled == true
    end
  end
end
