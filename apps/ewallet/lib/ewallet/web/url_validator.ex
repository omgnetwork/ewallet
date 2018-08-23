defmodule EWallet.Web.UrlValidator do
  @moduledoc """
  This module validates a url.
  """
  alias EWallet.Config

  @doc """
  Checks that the given url is allowed as a redirect url.
  """
  def allowed_redirect_url?(url) do
    :ewallet
    |> Config.get_strings(:redirect_url_prefixes)
    |> Enum.any?(fn prefix ->
      String.starts_with?(url, prefix)
    end)
  end
end
