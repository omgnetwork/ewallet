defmodule KuberaMQ.Publishers.Status do
  @moduledoc """
  Interface to the ledger status.
  """
  alias KuberaMQ.Publisher

  def check do
    Publisher.publish(Application.get_env(:kubera_mq, :mq_ledger_queue), %{
      operation: "status.check"
    })
  end
end
