defmodule AdminAPI.V1.WalletController do
  @moduledoc """
  The controller to serve wallets.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias AdminAPI.V1.AccountHelper
  alias EWallet.Web.{SearchParser, SortParser, Paginator}
  alias EWallet.{UUIDFetcher, WalletPolicy}
  alias EWalletDB.{Wallet, Account, User}

  @mapped_fields %{
    "created_at" => "inserted_at"
  }
  @search_fields [:id, :address, :name, :identifier]
  @sort_fields [:id, :address, :name, :identifier, :inserted_at, :updated_at]

  @doc """
  Retrieves a list of all wallets the accessor has access to (all accessible
  accounts + all user wallets)
  """
  @spec all(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all(conn, attrs) do
    with :ok <- permit(:all, conn.assigns, nil),
         account_uuids <- AccountHelper.get_accessible_account_uuids(conn.assigns) do
      Wallet
      |> Wallet.query_all_for_account_uuids_and_user(account_uuids)
      |> do_all(attrs, conn)
    else
      {:error, error} -> handle_error(conn, error)
      error -> handle_error(conn, error)
    end
  end

  @spec all_for_account(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all_for_account(conn, %{"id" => id, "owned" => true} = attrs) do
    with %Account{} = account <- Account.get(id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account) do
      account
      |> Wallet.all_for()
      |> do_all(attrs, conn)
    else
      {:error, error} -> handle_error(conn, error)
      error -> handle_error(conn, error)
    end
  end

  def all_for_account(conn, %{"id" => id} = attrs) do
    with %Account{} = account <- Account.get(id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, account),
         descendant_uuids <- Account.get_all_descendants_uuids(account) do
      Wallet
      |> Wallet.query_all_for_account_uuids(descendant_uuids)
      |> do_all(attrs, conn)
    else
      {:error, error} -> handle_error(conn, error)
      error -> handle_error(conn, error)
    end
  end

  def all_for_account(conn, _), do: handle_error(conn, :invalid_parameter)

  @spec all_for_user(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def all_for_user(conn, %{"id" => id} = attrs) do
    with %User{} = user <- User.get(id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, user) do
      user
      |> Wallet.all_for()
      |> do_all(attrs, conn)
    else
      {:error, error} -> handle_error(conn, error)
      error -> handle_error(conn, error)
    end
  end

  def all_for_user(conn, %{"provider_user_id" => provider_user_id} = attrs) do
    with %User{} = user <-
           User.get_by_provider_user_id(provider_user_id) || {:error, :unauthorized},
         :ok <- permit(:all, conn.assigns, user) do
      user
      |> Wallet.all_for()
      |> do_all(attrs, conn)
    else
      {:error, error} -> handle_error(conn, error)
      error -> handle_error(conn, error)
    end
  end

  def all_for_user(conn, _), do: handle_error(conn, :invalid_parameter)

  defp do_all(query, attrs, conn) do
    query
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
    |> Paginator.paginate_attrs(attrs)
    |> respond_multiple(conn)
  end

  @spec get(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def get(conn, %{"address" => address}) do
    with %Wallet{} = wallet <- Wallet.get(address) || {:error, :unauthorized},
         :ok <- permit(:get, conn.assigns, wallet) do
      respond_single(wallet, conn)
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  def get(conn, _), do: handle_error(conn, :invalid_parameter)

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, attrs) do
    with :ok <- permit(:create, conn.assigns, attrs) do
      attrs
      |> UUIDFetcher.replace_external_ids()
      |> Wallet.insert_secondary_or_burn()
      |> respond_single(conn)
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  @doc """
  Enable or disable a wallet.
  """
  @spec enable_or_disable(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def enable_or_disable(conn, %{"address" => address} = attrs) do
    with %Wallet{} = wallet <- Wallet.get(address) || {:error, :unauthorized},
         :ok <- permit(:enable_or_disable, conn.assigns, wallet),
         {:ok, updated} <- Wallet.enable_or_disable(wallet, attrs) do
      respond_single(updated, conn)
    else
      {:error, error} -> handle_error(conn, error)
    end
  end

  def enable_or_disable(conn, _),
    do: handle_error(conn, :invalid_parameter, "Invalid parameter provided. `address` is required.")

  # Respond with a list of wallets
  defp respond_multiple(%Paginator{} = paged_wallets, conn) do
    render(conn, :wallets, %{wallets: paged_wallets})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  # Respond with a single wallet
  defp respond_single({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp respond_single({:ok, wallet}, conn) do
    render(conn, :wallet, %{wallet: wallet})
  end

  defp respond_single(%Wallet{} = wallet, conn) do
    render(conn, :wallet, %{wallet: wallet})
  end

  @spec permit(:all | :create | :get | :update, map(), %Account{} | %User{} | %Wallet{} | nil) ::
          :ok | {:error, any()} | no_return()
  defp permit(action, params, data) do
    Bodyguard.permit(WalletPolicy, action, params, data)
  end
end
