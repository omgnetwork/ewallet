defmodule EWallet.ConfigTest do
  use ExUnit.Case, async: true
  alias EWallet.Config

  describe "get_boolean/1" do
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
end
