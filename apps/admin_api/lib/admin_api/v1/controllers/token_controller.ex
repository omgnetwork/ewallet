defmodule AdminAPI.V1.TokenController do
  @moduledoc """
  The controller to serve token endpoints.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.MintGate
  alias EWallet.Web.{SearchParser, SortParser, Paginator}
  alias EWalletDB.{Account, Token}
  alias Ecto.UUID
  alias Plug.Conn

  # The field names to be mapped into DB column names.
  # The keys and values must be strings as this is mapped early before
  # any operations are done on the field names. For example:
  # `"request_field_name" => "db_column_name"`
  @mapped_fields %{
    "created_at" => "inserted_at"
  }

  # The fields that are allowed to be searched.
  # Note that these values here *must be the DB column names*
  # Because requests cannot customize which fields to search (yet!),
  # `@mapped_fields` don't affect them.
  @search_fields [:id, :symbol, :name]

  # The fields that are allowed to be sorted.
  # Note that the values here *must be the DB column names*.
  # If the request provides different names, map it via `@mapped_fields` first.
  @sort_fields [:id, :symbol, :name, :subunit_to_unit, :inserted_at, :updated_at]

  @doc """
  Retrieves a list of tokens.
  """
  @spec all(Conn.t(), map() | nil) :: map()
  def all(conn, attrs) do
    Token
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
    |> Paginator.paginate_attrs(attrs)
    |> respond_multiple(conn)
  end

  @doc """
  Retrieves a specific token by its id.
  """
  @spec get(Conn.t(), map()) :: map()
  def get(conn, %{"id" => id}) do
    id
    |> Token.get()
    |> respond_single(conn)
  end

  def get(conn, _), do: handle_error(conn, :invalid_parameter)

  @doc """
  Creates a new Token.
  """
  @spec create(Conn.t(), map()) :: map()
  def create(conn, attrs) do
    inserted_token =
      attrs
      |> Map.put("account_uuid", Account.get_master_account().uuid)
      |> Token.insert()

    case attrs["amount"] do
      amount when is_number(amount) and amount > 0 ->
        inserted_token
        |> mint_token(%{"amount" => amount})
        |> respond_single(conn)

      _ ->
        respond_single(inserted_token, conn)
    end
  end

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
    with %Token{} = token <- Token.get(id) do
      mint_token({:ok, token}, attrs)
    else
      error -> error
    end
    |> respond_single(conn)
  end

  def mint(conn, _), do: handle_error(conn, :invalid_parameter)

  def stats(conn. %{"id" => id}) do
    # total supply
    # burn
  end

  defp mint_token({:ok, token}, %{"amount" => amount} = attrs)
       when is_number(amount) do
    %{
      "idempotency_token" => attrs["idempotency_token"] || UUID.generate(),
      "token_id" => token.id,
      "amount" => amount,
      "description" => attrs["description"]
    }
    |> MintGate.insert()
    |> case do
      {:ok, _mint, _transfer} -> {:ok, token}
      {:error, code, description} -> {:error, code, description}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp mint_token({:error, changeset}, _attrs), do: {:error, changeset}
  defp mint_token(_, _attrs), do: {:error, :invalid_parameter}

  # Respond with a list of tokens
  defp respond_multiple(%Paginator{} = paged_tokens, conn) do
    render(conn, :tokens, %{tokens: paged_tokens})
  end

  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  # Respond with a single token
  defp respond_single({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end

  defp respond_single({:ok, token}, conn) do
    render(conn, :token, %{token: token})
  end

  defp respond_single(%Token{} = token, conn) do
    render(conn, :token, %{token: token})
  end

  defp respond_single(nil, conn) do
    handle_error(conn, :token_id_not_found)
  end
end
