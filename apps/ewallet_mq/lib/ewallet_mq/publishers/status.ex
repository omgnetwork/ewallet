defmodule EWalletMQ.Publishers.Status do
  @moduledoc """
  Interface to the ledger status.
  """
  alias EWalletMQ.Publisher

  def check do
    Publisher.publish(Application.get_env(:ewallet_mq, :mq_ledger_queue), %{
      operation: "v1.status.check"
    })
  end
end
