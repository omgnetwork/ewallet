defmodule EWallet.Web.Date do
  @moduledoc """
  This module allows formatting of a date (naive or date time) into an iso8601 string.
  """

  alias EWallet.Errors.InvalidDateFormatError

  @doc """
  Parses the given date time to an iso8601 string.
  """
  def to_iso8601(%DateTime{} = date) do
    DateTime.to_iso8601(date)
  end

  @doc """
  Parses the given NaiveDateTime to an iso8601 string.
  """
  def to_iso8601(%NaiveDateTime{} = date) do
    NaiveDateTime.to_iso8601(date)
  end

  @doc """
  Returns nil if parsing nil.
  """
  def to_iso8601(nil) do
    nil
  end

  @doc """
  Raise a InvalidDateFormatError if the type is invalid.
  """
  def to_iso8601(_) do
    raise InvalidDateFormatError
  end
end
