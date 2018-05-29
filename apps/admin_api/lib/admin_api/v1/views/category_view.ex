defmodule AdminAPI.V1.CategoryView do
  use AdminAPI, :view
  alias EWallet.Web.V1.{ResponseSerializer, CategorySerializer}

  def render("category.json", %{category: category}) do
    category
    |> CategorySerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end

  def render("categories.json", %{categories: categories}) do
    categories
    |> CategorySerializer.serialize()
    |> ResponseSerializer.serialize(success: true)
  end
end
