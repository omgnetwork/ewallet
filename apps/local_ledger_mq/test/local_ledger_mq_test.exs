defmodule LocalLedgerMQTest do
  use ExUnit.Case
  doctest LocalLedgerMQ

  test "greets the world" do
    assert LocalLedgerMQ.hello() == :world
  end
end
