defmodule AdminAPI.V1.MintController do
  @moduledoc """
  The controller to serve mint endpoints.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias Ecto.Changeset
  alias EWallet.{MintGate, MintPolicy}
  alias EWallet.Web.{Orchestrator, Paginator, V1.MintOverlay}
  alias EWalletDB.{Mint, Token}
  alias Plug.Conn

  @doc """
  Retrieves a list of mints.
  """
  @spec all_for_token(Conn.t(), map() | nil) :: Conn.t()
  def all_for_token(conn, %{"id" => id} = attrs) do
    with :ok <- permit(:all, conn.assigns, nil),
         %Token{} = token <- Token.get(id) || :token_not_found,
         mints <- Mint.query_by_token(token),
         %Paginator{} = paged_mints <- Orchestrator.query(mints, MintOverlay, attrs) do
      render(conn, :mints, %{mints: paged_mints})
    else
      error -> handle_mint_error(conn, error)
    end
  end

  def all_for_token(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Mint a token.
  """
  @spec mint(Conn.t(), map()) :: Conn.t()
  def mint(
        conn,
        %{
          "id" => token_id,
          "amount" => _
        } = attrs
      ) do
    with :ok <- permit(:create, conn.assigns, token_id),
         %Token{} = token <- Token.get(token_id) || :token_not_found,
         {:ok, mint, _token} <- MintGate.mint_token(token, attrs),
         {:ok, mint} <- Orchestrator.one(mint, MintOverlay, attrs) do
      render(conn, :mint, %{mint: mint})
    else
      error -> handle_mint_error(conn, error)
    end
  end

  def mint(conn, _), do: handle_error(conn, :invalid_parameter)

  defp handle_mint_error(conn, {:error, code, description}) do
    handle_error(conn, code, description)
  end

  defp handle_mint_error(conn, {:error, %Changeset{} = changeset}) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp handle_mint_error(conn, {:error, code}) do
    handle_error(conn, code)
  end

  defp handle_mint_error(conn, error) do
    handle_error(conn, error)
  end

  @spec permit(:all | :create | :get | :update, map(), String.t() | nil) ::
          :ok | {:error, any()} | no_return()
  defp permit(action, params, account_id) do
    Bodyguard.permit(MintPolicy, action, params, account_id)
  end
end
