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
