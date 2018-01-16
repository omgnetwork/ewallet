defmodule KuberaAdmin.V1.MintedTokenController do
  @docmodule """
  The controller to serve minted token endpoints.
  """
  use KuberaAdmin, :controller
  import KuberaAdmin.V1.ErrorHandler
  alias Ecto.UUID
  alias Kubera.Web.{SearchParser, SortParser, Paginator}
  alias KuberaDB.MintedToken

  @search_fields [{:id, :uuid}, :friendly_id, :symbol, :name]
  @sort_fields [:id, :friendly_id, :symbol, :name]

  @doc """
  Retrieves a list of minted tokens.
  """
  def all(conn, attrs) do
    MintedToken
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields)
    |> Paginator.paginate_attrs(attrs)
    |> respond_multiple(conn)
  end

  @doc """
  Retrieves a specific minted token by its friendly_id.

  Note that the parameter key is "id" because from the caller's point of view,
  their `id` is our `friendly_id`, while our `id` is only used internally.
  """
  def get(conn, %{"id" => friendly_id}) do
    friendly_id
    |> MintedToken.get()
    |> respond_single(conn)
  end
  def get(conn, _), do: handle_error(conn, :invalid_parameter)

  # Respond with a list of minted tokens
  defp respond_multiple(%Paginator{} = paged_minted_tokens, conn) do
    render(conn, :minted_tokens, %{minted_tokens: paged_minted_tokens})
  end
  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  # Respond with a single minted token
  defp respond_single(%MintedToken{} = minted_token, conn) do
    render(conn, :minted_token, %{minted_token: minted_token})
  end
  defp respond_single(nil, conn) do
    handle_error(conn, :minted_token_id_not_found)
  end
end
