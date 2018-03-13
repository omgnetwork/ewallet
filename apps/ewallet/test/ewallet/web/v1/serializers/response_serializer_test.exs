defmodule EWallet.Web.V1.ResponseSerializerTest do
  use EWallet.Web.SerializerCase, :v1
  alias EWallet.Web.V1.ResponseSerializer

  describe "V1.ResponseSerializer" do
    test "serializes into correct V1 response format when successful" do
      result = ResponseSerializer.serialize("dummy_data", success: true)

      expected = %{
        success: true,
        version: "1",
        data: "dummy_data"
      }

      assert result == expected
    end
  end
end
