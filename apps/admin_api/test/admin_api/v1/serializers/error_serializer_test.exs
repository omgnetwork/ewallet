defmodule AdminAPI.V1.ErrorSerializerTest do
  use AdminAPI.SerializerCase, :v1
  alias AdminAPI.V1.ErrorSerializer

  describe "ErrorSerializer.serialize/3" do
    test "data contains the code, description and messages" do
      code        = "error_code"
      description = "This is the description"
      messages    = %{field: "required"}
      serialized  = ErrorSerializer.serialize(code, description, messages)

      assert serialized.object == "error"
      assert serialized.code == "error_code"
      assert serialized.description == "This is the description"
      assert serialized.messages == %{field: "required"}
    end
  end
end
