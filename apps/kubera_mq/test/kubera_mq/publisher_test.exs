defmodule CaishenMQ.PublisherTest do
  use ExUnit.Case
  alias KuberaMQ.Publisher

  test "sends an RPC call through RabbitMQ" do
    response = Publisher.publish(Application.get_env(:kubera_mq, :mq_ledger_queue),
                                 %{"hello" => "Universe"})
    assert response == {:ok, %{"hello" => "Universe"}}
  end
end
