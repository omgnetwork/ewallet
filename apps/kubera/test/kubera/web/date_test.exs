defmodule Kubera.Web.DateTest do
  use ExUnit.Case
  alias Kubera.Web.Date
  alias Kubera.Errors.InvalidDateFormatError

  describe "Kubera.Web.Date.to_iso8601/1" do
    test "formats a valid naive date time" do
      naive_date = ~N[2000-01-01 10:01:02]
      formatted_date = Date.to_iso8601(naive_date)

      assert formatted_date == "2000-01-01T10:01:02Z"
    end

    test "formats a normal date time" do
      {:ok, date, 0} = DateTime.from_iso8601("2000-01-01T10:01:02Z")
      formatted_date = Date.to_iso8601(date)

      assert formatted_date == "2000-01-01T10:01:02Z"
    end

    test "Raise an exception if the type is not supported" do
      assert_raise InvalidDateFormatError, fn ->
        Date.to_iso8601("an invalid type")
      end
    end
  end
end
