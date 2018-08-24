defmodule EWallet.Web.UrlValidator do
  @moduledoc """
  This module validates a url.
  """
  alias EWallet.Config

  @doc """
  Checks that the given url is allowed as a redirect url.
  """
  def allowed_redirect_url?(url) do
    base_url = Config.get_string(:ewallet, :base_url)
    prefixes = Config.get_strings(:ewallet, :redirect_url_prefixes)
    allowed = [base_url | prefixes]

    Enum.any?(allowed, fn prefix -> String.starts_with?(url, prefix) end)
  end
end
