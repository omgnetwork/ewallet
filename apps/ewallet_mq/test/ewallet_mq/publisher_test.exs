defmodule LocalLedgerMQ.PublisherTest do
  use ExUnit.Case
  alias EWalletMQ.Publisher

  test "sends an RPC call through RabbitMQ" do
    response = Publisher.publish(Application.get_env(:ewallet_mq, :mq_ledger_queue),
                                 %{"hello" => "Universe"})
    assert response == {:ok, %{"hello" => "Universe"}}
  end
end
