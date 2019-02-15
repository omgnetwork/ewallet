defmodule BlockchainEthTest do
  use ExUnit.Case
  doctest BlockchainEth

  test "greets the world" do
    assert BlockchainEth.hello() == :world
  end
end
