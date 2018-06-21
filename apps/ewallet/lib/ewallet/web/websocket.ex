# MIT License
# Copyright (c) 2014 Chris McCord
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software
# and associated documentation files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom
# the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
# ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

defmodule EWallet.Web.WebSocket do
  @moduledoc """
  Heavily inspired by https://hexdocs.pm/phoenix/Phoenix.Transports.WebSocket.html

  Socket transport for websocket clients.
  """

  @behaviour Phoenix.Socket.Transport

  def default_config do
    [timeout: 60_000, transport_log: false]
  end

  ## Callbacks

  import Plug.Conn, only: [send_resp: 3, assign: 3]

  require Logger

  alias Phoenix.Socket.Transport
  alias Phoenix.CodeReloader
  alias Phoenix.Transports.WebSocket

  @doc false
  def init(
        %Plug.Conn{method: "GET"} = conn,
        {_global_endpoint, handler, transport},
        endpoint,
        serializer,
        params
      ) do
    {_, opts} = handler.__transport__(transport)
    with conn <- code_reload(conn, opts, endpoint),
         conn <- Transport.transport_log(conn, opts[:transport_log]),
         conn <- Transport.force_ssl(conn, handler, endpoint, opts),
         conn <- Transport.check_origin(conn, handler, endpoint, opts),
         %{halted: false} = conn <- conn,
         {:ok, socket} <-
           Transport.connect(endpoint, handler, transport, __MODULE__, serializer, params) do
      {:ok, conn, {__MODULE__, {socket, opts}}}
    else
      _error ->
        {:error, conn}
    end
  end

  def init(conn, _) do
    conn = send_resp(conn, :bad_request, "")
    {:error, conn}
  end

  def get_endpoint(conn, accept, app, error_handler) when is_binary(accept) do
    case get_accept_version(accept, app) do
      {:ok, version} -> {:ok, version[:endpoint], version[:websocket_serializer]}
      _ -> invalid_version(conn, accept, error_handler)
    end
  end

  def get_endpoint(conn, accept, error_handler) do
    invalid_version(conn, accept, error_handler)
  end

  def invalid_version(conn, accept, error_handler) do
    conn =
      conn
      |> assign(:accept, inspect(accept))
      |> error_handler.(:invalid_version)

    {:error, conn}
  end

  def get_accept_version(accept, app) do
    app
    |> Application.get_env(:api_versions)
    |> Map.fetch(accept)
  end

  @doc false
  defdelegate ws_init(attrs), to: WebSocket
  defdelegate ws_handle(opcode, payload, state), to: WebSocket
  defdelegate ws_info(attrs, state), to: WebSocket
  defdelegate ws_terminate(reason, state), to: WebSocket
  defdelegate ws_close(state), to: WebSocket

  def code_reload(conn, opts, endpoint) do
    reload? = Keyword.get(opts, :code_reloader, endpoint.config(:code_reloader))
    _ = if reload?, do: CodeReloader.reload!(endpoint)

    conn
  end
end
