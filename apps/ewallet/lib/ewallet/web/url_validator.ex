defmodule EWallet.Web.UrlValidator do
  @moduledoc """
  This module validates a url.
  """

  @doc """
  Checks that the given url is allowed as a redirect url.
  """
  def allowed_redirect_url?(url) do
    base_url = Application.get_env(:ewallet, :base_url)
    prefixes = Application.get_env(:ewallet, :redirect_url_prefixes)
    allowed = [base_url | prefixes]

    Enum.any?(allowed, fn prefix -> String.starts_with?(url, prefix) end)
  end
end
