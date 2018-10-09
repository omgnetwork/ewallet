defmodule LoadTesterTest do
  use ExUnit.Case
  doctest LoadTester

  test "greets the world" do
    assert LoadTester.hello() == :world
  end
end
