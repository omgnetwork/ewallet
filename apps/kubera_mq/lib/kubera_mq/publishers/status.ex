defmodule KuberaMQ.Publishers.Status do
  @moduledoc """
  Interface to the ledger status.
  """
  alias KuberaMQ.Publisher

  def check do
    Publisher.publish(System.get_env("MQ_LEDGER_QUEUE"), %{
      operation: "status.check"
    })
  end
end
