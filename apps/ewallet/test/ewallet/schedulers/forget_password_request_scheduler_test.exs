defmodule EWallet.ForgetPasswordRequestSchedulerTest do
  use EWallet.DBCase, async: true
  alias EWallet.ForgetPasswordRequestScheduler
  alias EWalletDB.{ForgetPasswordRequest, Repo}

  describe "expire_all/0" do
    test "expires all requests past their expiration date" do
      now = NaiveDateTime.utc_now()

      # f1 and f2 have expiration dates in the past
      f1 = insert(:forget_password_request, expires_at: NaiveDateTime.add(now, -60, :seconds))
      f2 = insert(:forget_password_request, expires_at: NaiveDateTime.add(now, -600, :seconds))
      f3 = insert(:forget_password_request, expires_at: NaiveDateTime.add(now, 600, :seconds))
      f4 = insert(:forget_password_request, expires_at: NaiveDateTime.add(now, 160, :seconds))

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
