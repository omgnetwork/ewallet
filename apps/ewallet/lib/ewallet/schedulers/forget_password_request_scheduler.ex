defmodule EWallet.ForgetPasswordRequestScheduler do
  @moduledoc """
  Scheduler containing logic for CRON tasks related to
  forget password requests.
  """
  alias EWalletDB.ForgetPasswordRequest

  @doc """
  Expires all forget password requests which are
  past their expiration dates.
  """
  def expire_all do
    {:ok, _count} = ForgetPasswordRequest.expire_all()
  end
end
