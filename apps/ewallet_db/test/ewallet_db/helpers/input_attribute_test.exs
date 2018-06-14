defmodule EWalletDB.Helpers.InputAttributeTest do
  use ExUnit.Case
  alias EWalletDB.Helpers.InputAttribute

  describe "get/2" do
    test "returns the value if the map key is atom and argument is atom" do
      assert InputAttribute.get(%{match: "matched"}, :match) == "matched"
    end

    test "returns the value if the map key is string and argument is atom" do
      assert InputAttribute.get(%{"match" => "matched"}, :match) == "matched"
    end

    test "returns the value if the map key is string and argument is string" do
      assert InputAttribute.get(%{"match" => "matched"}, "match") == "matched"
    end

    test "returns the value if the map key is atom and argument is string" do
      assert InputAttribute.get(%{match: "matched"}, "match") == "matched"
    end
  end
end
