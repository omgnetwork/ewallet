defmodule EWallet.Web.UrlValidator do
  @moduledoc """
  This module validates a url.
  """

  @doc """
  Checks that the given url is allowed as a redirect url in the application settings.
  """
  def allowed_redirect_url?(url) do
    base_url = Application.get_env(:ewallet, :base_url)
    prefixes = Application.get_env(:ewallet, :redirect_url_prefixes)
    allowed = [base_url | prefixes]

    Enum.any?(allowed, fn prefix -> allowed_redirect_url?(url, prefix) end)
  end

  @doc """
  Checks that the given url is allowed by the given prefix
  """
  def allowed_redirect_url?(url, prefix) do
    # Add trailing slashes to prevent urls such as "https://example.comnotexample.com"
    # matching "https://example.com"
    url = trailing_slash(url)
    prefix = trailing_slash(prefix)

    String.starts_with?(url, prefix)
  end

  defp trailing_slash(string) do
    string |> URI.merge("/") |> to_string()
  end
end
