defmodule AdminAPI.V1.AdminUserAuth do
  @moduledoc """
  This module takes care of authenticating a provider for HTTP or Websocket connections.
  """
  alias EWalletDB.Key

  def parse_header(header) do
    with header when not is_nil(header) <- get_header(conn),
         [scheme, content] <- String.split(header, " ", parts: 2),
         true <- scheme in ["OMGAdmin"],
         {:ok, decoded} <- Base.decode64(content),
         [user_id, auth_token] <- String.split(decoded, ":", parts: 2) do
      {:ok, user_id, auth_token}
    else
      _ -> {:error, :invalid_auth_scheme}
    end
  end
end
