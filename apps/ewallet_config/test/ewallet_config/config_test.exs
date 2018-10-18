defmodule EWalletConfig.ConfigTest do
  use ExUnit.Case, async: true
  alias EWalletConfig.Config

  describe "get_boolean/2" do
    test "returns true when value is true" do
      Application.put_env(:ewallet, :config_true_boolean, true)
      assert Config.get_boolean(:ewallet, :config_true_boolean) == true
    end

    test "returns true when value is \"true\"" do
      Application.put_env(:ewallet, :config_true_string, "true")
      assert Config.get_boolean(:ewallet, :config_true_string) == true
    end

    test "returns true when value is 1" do
      Application.put_env(:ewallet, :config_one_integer, 1)
      assert Config.get_boolean(:ewallet, :config_one_integer) == true
    end

    test "returns true when value is \"1\"" do
      Application.put_env(:ewallet, :config_one_string, "1")
      assert Config.get_boolean(:ewallet, :config_one_string) == true
    end

    test "returns false when value is false" do
      Application.put_env(:ewallet, :config_false_boolean, false)
      assert Config.get_boolean(:ewallet, :config_false_boolean) == false
    end

    test "returns false when value is \"false\"" do
      Application.put_env(:ewallet, :config_false_string, "false")
      assert Config.get_boolean(:ewallet, :config_false_string) == false
    end

    test "returns false when value is 0" do
      Application.put_env(:ewallet, :config_zero_integer, 0)
      assert Config.get_boolean(:ewallet, :config_zero_integer) == false
    end

    test "returns false when value is \"0\"" do
      Application.put_env(:ewallet, :config_zero_string, "0")
      assert Config.get_boolean(:ewallet, :config_zero_string) == false
    end

    test "returns false when value is a empty string" do
      Application.put_env(:ewallet, :config_empty_string, "0")
      assert Config.get_boolean(:ewallet, :config_empty_string) == false
    end

    test "returns false when value is nil" do
      Application.put_env(:ewallet, :config_nil, nil)
      assert Config.get_boolean(:ewallet, :config_nil) == false
    end
  end

  describe "get_string/2" do
    test "returns a string" do
      Application.put_env(:ewallet, :test_get_string, "some_string")
      assert Config.get_string(:ewallet, :test_get_string) == "some_string"
    end

    test "returns nil if the key could not be found" do
      assert Config.get_string(:ewallet, :test_get_string_not_exists) == nil
    end
  end

  describe "get_strings/2" do
    test "returns a list of strings" do
      Application.put_env(:ewallet, :test_get_strings, "one,two,three")
      assert Config.get_strings(:ewallet, :test_get_strings) == ["one", "two", "three"]
    end

    test "returns the strings trimmed" do
      Application.put_env(:ewallet, :test_get_strings, "   one ,   two ,three    ")
      assert Config.get_strings(:ewallet, :test_get_strings) == ["one", "two", "three"]
    end

    test "returns without empty strings" do
      Application.put_env(:ewallet, :config_get_strings, "one, two, , three,,,")
      assert Config.get_strings(:ewallet, :config_get_strings) == ["one", "two", "three"]
    end

    test "returns an empty list if the config is nil" do
      Application.put_env(:ewallet, :test_get_strings, nil)
      assert Config.get_strings(:ewallet, :test_get_strings) == []
    end

    test "returns an empty list if the config is a blank string" do
      Application.put_env(:ewallet, :test_get_strings, "")
      assert Config.get_strings(:ewallet, :test_get_strings) == []
    end

    test "returns an empty list if all strings are trimmable" do
      Application.put_env(:ewallet, :test_get_strings, ",   , ,   , , ,,,")
      assert Config.get_strings(:ewallet, :test_get_strings) == []
    end
  end
end
