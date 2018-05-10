defmodule EWallet.TransactionRequestScheduler do
  @moduledoc """
  Scheduler containing logic for CRON tasks related to
  transaction requests.
  """
  alias EWalletDB.TransactionRequest

  @doc """
  Expires all transaction request which are
  past their expiration dates.
  """
  def expire_all do
    TransactionRequest.expire_all()
  end
end
