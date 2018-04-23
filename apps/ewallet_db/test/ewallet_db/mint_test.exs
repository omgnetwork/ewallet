defmodule EWalletDB.MintTest do
  use EWalletDB.SchemaCase
  alias EWalletDB.Mint

  describe "Mint factory" do
    test_has_valid_factory(Mint)
  end

  describe "insert/1" do
    test_insert_generate_uuid(Mint, :uuid)
    test_insert_generate_external_id(Mint, :id, "mnt_")
    test_insert_generate_timestamps(Mint)
    test_insert_prevent_blank(Mint, :amount)
    test_insert_prevent_blank(Mint, :minted_token_uuid)
  end
end
