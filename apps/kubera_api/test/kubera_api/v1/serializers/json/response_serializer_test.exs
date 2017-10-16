defmodule KuberaAPI.V1.ResponseSerializerTest do
  use ExUnit.Case
  alias KuberaAPI.V1.JSON.ResponseSerializer

  describe "V1.JSON.ResponseSerializer" do
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
