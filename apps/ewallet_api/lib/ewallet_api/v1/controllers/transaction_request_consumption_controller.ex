defmodule EWalletAPI.V1.TransactionRequestConsumptionController do
  use EWalletAPI, :controller
  import EWalletAPI.V1.ErrorHandler
  alias EWallet.TransactionConsumptionGate
  alias EWalletDB.Repo

  # The fields that are allowed to be preloaded.
  # These fields must be one of the schema's association names.
  @preloadable [:account, :minted_token, :transaction, :transaction_request, :user]

  # The fields in `@preloadable` that are preloaded regardless of the request.
  # These fields must be one of the schema's association names.
  @always_preload [:minted_token]

  plug :response_preload

  def consume(%{assigns: %{user: _}} = conn, attrs) do
    attrs = Map.put(attrs, "idempotency_token", conn.assigns.idempotency_token)

    conn.assigns.user
    |> TransactionConsumptionGate.consume(attrs)
    |> respond(conn)
  end

  def consume(%{assigns: %{account: _}} = conn, attrs) do
    attrs
    |> Map.put("idempotency_token", conn.assigns.idempotency_token)
    |> TransactionConsumptionGate.consume()
    |> respond(conn)
  end

  defp respond({:error, error}, conn) when is_atom(error), do: handle_error(conn, error)
  defp respond({:error, changeset}, conn) do
    handle_error(conn, :invalid_parameter, changeset)
  end
  defp respond({:error, code, description}, conn) do
    handle_error(conn, code, description)
  end
  defp respond({:ok, consumption}, conn) do
    render(conn, :transaction_request_consumption, %{
      transaction_request_consumption: preload_embed(conn, consumption)
    })
  end

  defp preload_embed(conn, item), do: Repo.preload(item, conn.assigns.embed)

  def response_preload(conn, _plug_opts) do
    embeds =
      case conn.body_params["embed"] do
        embeds when is_list(embeds) -> to_existing_atoms!(embeds)
        _                           -> []
      end

    # We could use `preloads -- (preloads -- preloadable)` but the complexity is O(N^3)
    # and we're dealing with user inputs here, so it's better to convert to `MapSet`
    # before operating on the lists.
    preloads    = MapSet.new(embeds ++ @always_preload)
    preloadable = MapSet.new(@preloadable)
    filtered    = MapSet.intersection(preloads, preloadable)

    case MapSet.size(filtered) do
      n when n > 0 -> assign(conn, :embed, MapSet.to_list(filtered))
      _            -> assign(conn, :embed, [])
    end
  end

  defp to_existing_atoms!(strings), do: Enum.map(strings, &String.to_existing_atom/1)
end
