defmodule AdminAPI.StatusControllerTest do
  use AdminAPI.ConnCase, async: true

  describe "GET request to /" do
    test "returns status ok" do
      response =
        build_conn()
        |> get(@base_dir <> "/")
        |> json_response(:ok)

      assert response == %{
               "success" => true,
               "ewallet_version" => "1.1.0",
               "api_versions" => [
                 %{"name" => "v1", "media_type" => "application/vnd.omisego.v1+json"}
               ]
             }
    end
  end
end
