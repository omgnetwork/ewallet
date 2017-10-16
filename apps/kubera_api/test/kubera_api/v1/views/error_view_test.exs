defmodule KuberaAPI.V1.ErrorViewTest do
  use KuberaAPI.ViewCase, :v1
  alias KuberaAPI.V1.ErrorView

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  describe "KuberaAPI.V1.ErrorView" do
    test "renders error.json with custom error code and message" do
      expected = %{
        version: "1",
        success: false,
        data: %{
          "object" => "error",
          "code" => "custom_code",
          "message" => "Custom message"
        }
      }

      assert render(ErrorView, "error.json", 
        %{code: "custom_code", message: "Custom message"}) == expected
    end

    test "renders bad_request.json with correct error response format" do
      expected = %{
        version: "1",
        success: false,
        data: %{
          "object" => "error",
          "code" => "bad_request",
          "message" => "Bad request"
        }
      }

      assert render(ErrorView, "bad_request.json", []) == expected
    end

    test "renders not_found.json with correct error response format" do
      expected = %{
        version: "1",
        success: false,
        data: %{
          "object" => "error",
          "code" => "not_found",
          "message" => "Not found"
        }
      }

      assert render(ErrorView, "not_found.json", []) == expected
    end

    test "renders server_error.json with correct error response format" do
      expected = %{
        version: "1",
        success: false,
        data: %{
          "object" => "error",
          "code" => "internal_server_error",
          "message" => "Internal server error"
        }
      }

      assert render(ErrorView, "server_error.json", []) == expected
    end
  end
end
