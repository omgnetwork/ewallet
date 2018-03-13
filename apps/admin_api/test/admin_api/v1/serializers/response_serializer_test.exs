defmodule AdminAPI.V1.ResponseSerializerTest do
  use AdminAPI.SerializerCase, :v1
  alias AdminAPI.V1.ResponseSerializer

  describe "ResponseSerializer.serialize/2" do
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
