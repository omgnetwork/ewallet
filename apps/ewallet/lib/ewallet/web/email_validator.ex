defmodule EWallet.EmailValidator do
  @moduledoc """
  This module validates an email string.
  """
  @email_regex ~r/^[^\@]+\@[^\@]+$/

  @doc """
  Checks whether the email address looks correct.
  """
  @spec valid?(String.t() | nil) :: boolean()
  def valid?(nil), do: false

  def valid?(email) do
    Regex.match?(@email_regex, email)
  end

  @doc """
  Checks whether the email address looks correct.
  Returns `{:ok, email}` if valid, returns `{:error, :invalid_email}` if invalid.
  """
  @spec validate(String.t() | nil) :: {:ok, String.t()} | {:error, :invalid_email}
  def validate(nil), do: {:error, :invalid_email}

  def validate(email) do
    if Regex.match?(@email_regex, email) do
      {:ok, email}
    else
      {:error, :invalid_email}
    end
  end
end
