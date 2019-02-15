defmodule BlockchainTest do
  use ExUnit.Case
  doctest Blockchain

  test "greets the world" do
    assert Blockchain.hello() == :world
  end
end
