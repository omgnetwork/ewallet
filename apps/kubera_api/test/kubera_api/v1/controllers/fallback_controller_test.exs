defmodule KuberaAPI.V1.FallbackControllerTest do
  use KuberaAPI.ConnCase, async: true

  describe "/not_found" do
    test "returns correct error response format and error message" do
      expected = %{
        "version" => "1",
        "success" => false,
        "data" => %{
          "object" => "error",
          "code" => "client:endpoint_not_found",
          "description" => "Endpoint not found",
          "messages" => nil
        }
      }

      assert provider_request("/not_found") == expected
    end
  end
end
