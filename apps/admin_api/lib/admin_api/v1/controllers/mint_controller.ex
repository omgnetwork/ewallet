defmodule AdminAPI.V1.MintController do
  @moduledoc """
  The controller to serve mint endpoints.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.MintGate
  alias EWallet.Web.{SortParser, Paginator, Preloader}
  alias EWalletDB.{Token, Mint}
  alias Plug.Conn

  @mapped_fields %{
    "created_at" => "inserted_at"
  }
  @sort_fields [:id, :description, :amount, :confirmed, :inserted_at, :updated_at]
  @preload_fields [:token, :account, :transfer]

  @doc """
  Retrieves a list of mints.
  """
  @spec all_for_token(Conn.t(), map() | nil) :: map()
  def all_for_token(conn, %{"id" => id} = attrs) do
    with %Token{} = token <- Token.get(id) || :token_id_not_found do
      token
      |> Mint.for_token()
      |> Preloader.to_query(@preload_fields)
      |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
      |> Paginator.paginate_attrs(attrs)
      |> respond_multiple(conn)
    else
      error -> handle_error(conn, error)
    end
  end

  def all_for_token(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Mint a token.
  """
  @spec mint(Conn.t(), map()) :: map()
  def mint(
        conn,
        %{
          "id" => id,
          "amount" => _
        } = attrs
      ) do
    with %Token{} = token <- Token.get(id) || :token_id_not_found do
      token
      |> MintGate.mint_token(attrs)
      |> respond_single(conn)
    else
      error -> handle_error(conn, error)
    end
  end

  def mint(conn, _), do: handle_error(conn, :invalid_parameter)

  # Respond with a list of mints
  defp respond_multiple(%Paginator{} = paged_mints, conn) do
    render(conn, :mints, %{mints: paged_mints})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  # Respond with a single mint
  defp respond_single({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp respond_single({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  defp respond_single({:ok, mint, _token}, conn) do
    render(conn, :mint, %{mint: mint})
  end
end
