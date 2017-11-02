defmodule CaishenMQ.PublisherTest do
  use ExUnit.Case
  alias KuberaMQ.{Consumer, Publisher}

  test "sends an RPC call through RabbitMQ" do
    {:ok, _pid} = Consumer.start_link()

    Publisher.send(%{hello: "Universe"}, fn response ->
      assert response == {:ok, %{"hello" => "Universe"}}
    end)
  end
end
