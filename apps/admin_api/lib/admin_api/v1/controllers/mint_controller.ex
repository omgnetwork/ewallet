defmodule AdminAPI.V1.MintController do
  @moduledoc """
  The controller to serve mint endpoints.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.MintGate
  alias EWallet.Web.{SearchParser, SortParser, Paginator}
  alias EWalletDB.{Mint}
  alias Ecto.UUID
  alias Plug.Conn

  @mapped_fields %{
    "created_at" => "inserted_at"
  }
  @search_fields [:id, :description, :amount, :confirmed]
  @sort_fields [:id, :description, :amount, :confirmed, :inserted_at, :updated_at]

  @doc """
  Retrieves a list of mints.
  """
  @spec all(Conn.t(), map() | nil) :: map()
  def all(conn, %{"id" => id}) do
    Mint
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
    |> Paginator.paginate_attrs(attrs)
    |> respond_multiple(conn)
  end

  # Respond with a list of mints
  defp respond_multiple(%Paginator{} = paged_mints, conn) do
    render(conn, :mints, %{mints: paged_mints})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end
end
