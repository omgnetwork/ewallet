defmodule EWallet.Web.V1.ClientAuth do
  @moduledoc """
  This module takes care of authenticating a client for HTTP or Websocket connections.
  """
  alias EWalletDB.{APIKey, AuthToken}

  def parse_header(header) do
    with header when not is_nil(header) <- header,
         [scheme, content] <- String.split(header, " ", parts: 2),
         true <- scheme in ["Basic", "OMGClient"],
         {:ok, decoded} <- Base.decode64(content),
         [key, token] <- String.split(decoded, ":", parts: 2) do
      {:ok, key, token}
    else
      _ ->
        {:error, :invalid_auth_scheme}
    end
  end

  def authenticate_client(api_key, owner_app) do
    case APIKey.authenticate(api_key, owner_app) do
      false ->
        {:error, :invalid_api_key}

      account ->
        {:ok, account}
    end
  end

  def authenticate_token(auth_token, owner_app) do
    case AuthToken.authenticate(auth_token, owner_app) do
      false -> {:error, :auth_token_not_found}
      :token_expired -> {:error, :auth_token_expired}
      user -> {:ok, user}
    end
  end

  def expire_token(token_string, app) do
    AuthToken.expire(token_string, app)
  end
end
