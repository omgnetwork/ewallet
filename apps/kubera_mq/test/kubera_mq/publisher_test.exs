defmodule CaishenMQ.PublisherTest do
  use ExUnit.Case
  alias KuberaMQ.Publisher

  test "sends an RPC call through RabbitMQ" do
    response = Publisher.publish(System.get_env("MQ_LEDGER_QUEUE"),
                                 %{"hello" => "Universe"})
    assert response == {:ok, %{"hello" => "Universe"}}
  end
end
