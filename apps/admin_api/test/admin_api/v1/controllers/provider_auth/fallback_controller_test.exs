defmodule AdminAPI.V1.ProviderAuth.FallbackControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "/not_found" do
    test "returns correct error response for client-authtenticated requests" do
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

      assert unauthenticated_request("/not_found") == expected
    end

    test "returns correct error response for user-authenticated requests" do
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
