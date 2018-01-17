defmodule EWalletMQ.Publishers.Balance do
  @moduledoc """
  Interface to the ledger Transactions records.
  """
  alias EWalletMQ.Publisher

  def all(address) do
    Publisher.publish(Application.get_env(:ewallet_mq, :mq_ledger_queue), %{
      operation: "v1.balance.all",
      address: address
    })
  end

  def get(friendly_id, address) do
    Publisher.publish(Application.get_env(:ewallet_mq, :mq_ledger_queue), %{
      operation: "v1.balance.get",
      friendly_id: friendly_id,
      address: address
    })
  end
end
