defmodule EWallet.EmailValidator do
  @moduledoc """
  This module validates an email string.
  """
  @email_regex ~r/^[^\@]+\@[^\@]+$/

  @doc """
  Checks whether the email address looks correct.
  """
  @spec valid?(String.t()) :: String.t() | boolean()
  def valid?(email) do
    Regex.match?(@email_regex, email)
  end

  @doc """
  Checks whether the email address looks correct.
  Returns the email string if valid, returns false if invalid.
  """
  def validate(email) do
    if Regex.match?(@email_regex, email), do: email, else: false
  end
end
