defmodule AdminAPI.V1.MintedTokenController do
  @moduledoc """
  The controller to serve minted token endpoints.
  """
  use AdminAPI, :controller
  import AdminAPI.V1.ErrorHandler
  alias EWallet.MintGate
  alias EWallet.Web.{SearchParser, SortParser, Paginator}
  alias EWalletDB.MintedToken

  # The field names to be mapped into DB column names.
  # The keys and values must be strings as this is mapped early before
  # any operations are done on the field names. For example:
  # `"request_field_name" => "db_column_name"`
  @mapped_fields %{
    "id" => "friendly_id",
    "created_at" => "inserted_at"
  }

  # The fields that are allowed to be searched.
  # Note that these values here *must be the DB column names*
  # Because requests cannot customize which fields to search (yet!),
  # `@mapped_fields` don't affect them.
  @search_fields [:friendly_id, :symbol, :name]

  # The fields that are allowed to be sorted.
  # Note that the values here *must be the DB column names*.
  # If the request provides different names, map it via `@mapped_fields` first.
  @sort_fields [:friendly_id, :symbol, :name, :subunit_to_unit, :inserted_at, :updated_at]

  @doc """
  Retrieves a list of minted tokens.
  """
  def all(conn, attrs) do
    MintedToken
    |> SearchParser.to_query(attrs, @search_fields)
    |> SortParser.to_query(attrs, @sort_fields, @mapped_fields)
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

  @doc """
  Creates a new Minted Token.
  """
  def create(%{assigns: %{account: account}} = conn, attrs) do
    attrs
    |> Map.put("account_id", account.id)
    |> MintedToken.insert()
    |> mint(attrs)
    |> respond_single(conn)
  end
  def create(conn, _), do: handle_error(conn, :invalid_parameter)

  defp mint({:ok, minted_token}, %{
    "amount" => amount
  })
    when not is_nil(amount)
    and is_integer(amount)
    and amount > 0
  do
    res = MintGate.insert(%{
      "idempotency_token" => minted_token.id,
      "token_id" => minted_token.friendly_id,
      "amount" => amount,
      "description" => ""
    })

    case res do
      {:ok, _mint, _ledger_response} -> {:ok, minted_token}
      {:error, code, description}    -> {:error, code, description}
      {:error, changeset}            -> {:error, changeset}
    end
  end
  defp mint(res, _attrs), do: res

  # Respond with a list of minted tokens
  defp respond_multiple(%Paginator{} = paged_minted_tokens, conn) do
    render(conn, :minted_tokens, %{minted_tokens: paged_minted_tokens})
  end
  defp respond_multiple({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end

  # Respond with a single minted token
  defp respond_single({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end
  defp respond_single({:ok, minted_token}, conn) do
    render(conn, :minted_token, %{minted_token: minted_token})
  end
  defp respond_single(%MintedToken{} = minted_token, conn) do
    render(conn, :minted_token, %{minted_token: minted_token})
  end
  defp respond_single(nil, conn) do
    handle_error(conn, :minted_token_id_not_found)
  end
end
