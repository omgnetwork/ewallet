defmodule Kubera.Web.Date do
  @moduledoc """
  This module allows formatting of a date (naive or date time) into an iso8601 string.
  """

  alias Kubera.Errors.InvalidDateFormatError

  @doc """
  Parses the given naive date time to an iso8601 string.
  """
  def to_iso8601(%NaiveDateTime{} = date) do
    date
    |> DateTime.from_naive!("Etc/UTC")
    |> to_iso8601()
  end

  @doc """
  Parses the given date time to an iso8601 string.
  """
  def to_iso8601(%DateTime{} = date) do
    DateTime.to_iso8601(date)
  end
  @doc """
  Raise a InvalidDateFormatError if the type is invalid.
  """
  def to_iso8601(_) do
    raise InvalidDateFormatError
  end
end
