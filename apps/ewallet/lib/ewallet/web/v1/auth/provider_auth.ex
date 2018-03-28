defmodule EWallet.Web.V1.ProviderAuth do
  @moduledoc """
  This module takes care of authenticating a provider for HTTP or Websocket connections.
  """
  alias EWalletDB.Key

  def parse_header(header) do
    with header when not is_nil(header) <- header,
         [scheme, content] <- String.split(header, " ", parts: 2),
         true <- scheme in ["Basic", "OMGServer"],
         {:ok, decoded} <- Base.decode64(content),
         [access, secret] <- String.split(decoded, ":", parts: 2)
    do
      {:ok, access, secret}
    else
      _ -> {:error, :invalid_auth_scheme}
    end
  end

  def authenticate(access_key, secret_key) do
    case Key.authenticate(access_key, secret_key) do
      false   -> {:error, :invalid_access_secret_key}
      account -> {:ok, account}
    end
  end
end
