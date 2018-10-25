defmodule EWalletConfig.MultiNodeTest do
  use ExUnit.Case, async: false
  alias EWalletConfig.{Config, Repo, ConfigTestHelper}
  alias Ecto.Adapters.SQL.Sandbox

  describe "reload_config/1" do
    test "reloads all settings for all nodes" do
      Sandbox.checkout(Repo)

      ConfigTestHelper.spawn([:test1, :test2, :test3])
      nodes = [Node.self() | Node.list()]

      Enum.each(nodes, fn node ->
        :rpc.block_call(node, Sandbox, :checkout, [Repo])
      end)

      Sandbox.mode(Repo, {:shared, self()})

      Config.insert(%{key: "my_setting", value: "some_value", type: "string"})

      Enum.each(nodes, fn node ->
        :ok = Config.register_and_load(:my_app, [:my_setting], {Config, node})
        value = :rpc.block_call(node, Application, :get_env, [:my_app, :my_setting])
        assert value == "some_value"
      end)

      Config.update("my_setting", %{value: "new_value"})

      Enum.each(nodes, fn node ->
        value = :rpc.block_call(node, Application, :get_env, [:my_app, :my_setting])
        assert value == "new_value"
      end)
    end
  end
end
