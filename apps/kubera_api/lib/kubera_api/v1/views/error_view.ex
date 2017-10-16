defmodule KuberaAPI.V1.ErrorView do
  use KuberaAPI, :view
  alias KuberaAPI.V1.JSON.{ErrorSerializer, ResponseSerializer}

  # Error with provided custom error code and message
  def render("error.json", %{code: code, message: message}) do
    render_error(code, message)
  end

  # Bad request with default error code and message
  def render("bad_request.json", _assigns) do
    render_error("bad_request", "Bad request")
  end

  # Not found with default error code and message
  def render("not_found.json", _assigns) do
    render_error("not_found", "Not found")
  end

  # Server error with default error code and message
  def render("server_error.json", _assigns) do
    render_error("internal_server_error", "Internal server error")
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "server_error.json", assigns
  end

  defp render_error(code, message) do
    code
    |> ErrorSerializer.serialize(message)
    |> ResponseSerializer.serialize(success: false)
  end
end
