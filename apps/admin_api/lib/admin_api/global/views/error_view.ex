defmodule AdminAPI.ErrorView do
  @moduledoc """
  Global error view used by non-versioned errors.
  """
  use AdminAPI, :view
  alias EWallet.Web.V1.{ErrorSerializer, ResponseSerializer}

  @doc """
  Supports internal server error thrown by Phoenix.
  """
  def render("500.json", %{reason: %{message: message}}) do
    render_error("server:internal_server_error", message)
  end

  @doc """
  Supports bad request error thrown by Phoenix.
  """
  def render("400.json", %{reason: %{message: message}}) do
    render_error("client:invalid_parameter", message)
  end

  @doc """
  Renders error when no render clause matches or no template is found.
  """
  def template_not_found(_template, _assigns) do
    render_error(
      "server:internal_server_error",
      "Something went wrong on the server"
    )
  end

  @doc """
  Renders the error code and message into actual json response.
  """
  def render_error(code, message) do
    code
    |> ErrorSerializer.serialize(message)
    |> ResponseSerializer.serialize(success: false)
  end
end
