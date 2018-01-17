defmodule AdminAPI.ErrorViewTest do
  use AdminAPI.ViewCase, :v1
  alias AdminAPI.ErrorView

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  describe "AdminAPI.ErrorView.render/2" do
    # Potential candidate to be moved to a shared library
    # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
    test "renders 500.json with correct structure given a custom description" do
      assigns = %{
        reason: %{
          message: "Custom assigned error description"
        }
      }

      expected = %{
        version: "1",
        success: false,
        data: %{
          object: "error",
          code: "server:internal_server_error",
          description: "Custom assigned error description",
          messages: nil
        }
      }

      assert render(ErrorView, "500.json", assigns) == expected
    end

    test "renders invalid template as server error" do
      expected = %{
        version: "1",
        success: false,
        data: %{
          object: "error",
          code: "server:internal_server_error",
          description: "Something went wrong on the server",
          messages: nil
        }
      }

      assert render(ErrorView, "invalid_template.json", []) == expected
    end
  end
end
