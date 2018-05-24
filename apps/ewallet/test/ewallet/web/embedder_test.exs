defmodule EWallet.Web.EmbedderTest do
  use EWallet.DBCase
  import EWalletDB.Factory
  alias Ecto.Association.NotLoaded
  alias EWalletDB.Account

  defmodule TestModule do
    use EWallet.Web.Embedder

    @embeddable [:wallets, :tokens]
    @always_embed [:wallets]

    def call_embed(record, embeds) do
      embed(record, embeds)
    end
  end

  # A `Factory.insert/1` may contain preloaded associations. So we need to insert,
  # then do a clean `get/1` to make sure no associations are preloaded.
  defp insert_and_get_account do
    :account
    |> insert()
    |> Map.get(:id)
    |> Account.get()
  end

  describe "EWallet.Web.Embedder.embed/2" do
    test "returns the embed defined in @always_embed by default" do
      account = insert_and_get_account()
      assert %NotLoaded{} = account.wallets

      embedded = TestModule.call_embed(account, [])
      assert is_list(embedded.wallets)
    end

    test "returns the embed and @always_embed if the given field is in @embeddable" do
      account = insert_and_get_account()
      assert %NotLoaded{} = account.tokens

      embedded = TestModule.call_embed(account, ["tokens"])
      assert is_list(embedded.wallets)
      assert is_list(embedded.tokens)
    end

    test "returns without embed if the given field is not in @embeddable" do
      account = insert_and_get_account()
      assert %NotLoaded{} = account.keys

      embedded = TestModule.call_embed(account, ["keys"])
      assert %NotLoaded{} = embedded.keys
    end

    test "ignores unknown embed fields" do
      account = insert_and_get_account()
      assert %NotLoaded{} = account.keys

      embedded = TestModule.call_embed(account, ["does_not_exist", "also_does_not_exist"])
      assert account.id == embedded.id
      refute Map.has_key?(embedded, :does_not_exist)
      refute Map.has_key?(embedded, :also_does_not_exist)
    end
  end
end
