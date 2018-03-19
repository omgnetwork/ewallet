defmodule EWallet.HelperTest do
  use ExUnit.Case
  alias EWallet.Helper

  describe "to_existing_atoms/1" do
    test "converts strings to atoms" do
      # Atoms exist since compile, so by the time we invoke the asserted atoms would already exist.
      assert Helper.to_existing_atoms(["one", "two"]) == [:one, :two]
    end

    test "skips strings that are not existing atoms" do
      # Atoms exist since compile, so by the time we invoke the asserted atoms would already exist.
      assert Helper.to_existing_atoms(["exists", "doesnt_exist_anywhere_z93Gh4g0f"]) == [:exists]
    end
  end
end
