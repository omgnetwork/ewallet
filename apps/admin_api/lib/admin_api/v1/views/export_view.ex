defmodule AdminAPI.V1.ExportView do
  use AdminAPI, :view
  alias EWallet.Web.V1.{ExportSerializer, ResponseSerializer}

  def render("export.json", %{export: export}) do
    export
    |> ExportSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("exports.json", %{exports: exports}) do
    exports
    |> ExportSerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
