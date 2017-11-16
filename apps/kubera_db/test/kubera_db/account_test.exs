defmodule KuberaDB.AccountTest do
  use KuberaDB.SchemaCase
  alias KuberaDB.Account

  describe "Account factory" do
    test_has_valid_factory Account
  end

  describe "Account.insert/1" do
    test_insert_generate_uuid Account, :id
    test_insert_generate_timestamps Account
    test_insert_prevent_blank Account, :name
    test_insert_prevent_duplicate Account, :name
  end
end
