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

    Enum.any?(allowed, fn prefix -> allowed_redirect_url?(url, prefix) end)
  end

  def allowed_redirect_url?(url, prefix) do
    # Add trailing slashes to prevent urls such as 'https://example.comnotexample.com'
    # matching 'https://example.com'
    url = trailing_slashed(url)
    prefix = trailing_slashed(prefix)

    String.starts_with?(url, prefix)
  end

  defp trailing_slashed(string) do
    if String.ends_with?(string, "/"), do: string, else: string <> "/"
  end
end
