defmodule EWalletAPI.WebSocket do
  @moduledoc """
  Heavily inspired by https://hexdocs.pm/phoenix/Phoenix.Transports.WebSocket.html

  Socket transport for websocket clients.
  """

  # MIT License
  # Copyright (c) 2014 Chris McCord
  #
  # Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
  #
  # The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
  #
  # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

  @behaviour Phoenix.Socket.Transport

  def default_config() do
    [timeout: 60_000,
     transport_log: false]
  end

  ## Callbacks

  import Plug.Conn, only: [fetch_query_params: 1, get_req_header: 2, send_resp: 3, assign: 3]
  import EWalletAPI.V1.ErrorHandler

  require Logger

  alias Phoenix.Socket
  alias Phoenix.Socket.Broadcast
  alias Phoenix.Socket.Transport

  @doc false
  def init(%Plug.Conn{method: "GET"} = conn, {_global_endpoint, handler, transport}) do
    {_, opts} = handler.__transport__(transport)

    with accept <- Enum.at(get_req_header(conn, "accept"), 0),
         {:ok, endpoint, serializer} <- get_endpoint(conn, accept),
         conn <- code_reload(conn, opts, endpoint),
         conn <- fetch_query_params(conn),
         conn <- Transport.transport_log(conn, opts[:transport_log]),
         conn <- Transport.force_ssl(conn, handler, endpoint, opts),
         conn <- Transport.check_origin(conn, handler, endpoint, opts),
         %{halted: false} = conn <- conn,
         params <- conn.params |> Map.put_new(:http_headers, conn.req_headers),
         {:ok, socket} <- connect(endpoint, handler, transport, __MODULE__, serializer, params)
    do
      {:ok, conn, {__MODULE__, {socket, opts}}}
    else
      _error ->
        conn = send_resp(conn, 403, "abccc")
        {:error, conn}
      # error when is_atom(error) ->
      #   conn = send_resp(conn, 403, "abccc")
      #   {:error, conn}
      # {:error, %Plug.Conn{} = conn} ->
      #   conn = send_resp(conn, 403, "def")
      #   {:error, conn}
      # {:error, _code} ->
      #   conn = send_resp(conn, 403, "zyx")
      #   {:error, conn}
    end
  end

  def init(conn, _) do
    conn = send_resp(conn, :bad_request, "")
    {:error, conn}
  end

  defp get_endpoint(conn, accept) when is_binary(accept) do
    case get_accept_version(accept) do
      {:ok, version} -> {:ok, version[:endpoint], version[:websocket_serializer]}
      _              -> invalid_version(conn, accept)
    end
  end

  defp get_endpoint(conn, accept) do
    invalid_version(conn, accept)
  end

  defp invalid_version(conn, accept) do
    conn =
      conn
      |> assign(:accept, inspect(accept))
      |> handle_error(:invalid_version)

    {:error, conn}
  end

  defp get_accept_version(accept) do
    api_version = Application.get_env(:ewallet_api, :api_versions)
    Map.fetch(api_version, accept)
  end

  def connect(endpoint, handler, transport_name, transport, serializer, params, pid \\ self()) do
    vsn = params["vsn"] || "1.0.0"

    socket = %Socket{endpoint: endpoint,
                     transport: transport,
                     transport_pid: pid,
                     transport_name: transport_name,
                     handler: handler,
                     vsn: vsn,
                     pubsub_server: endpoint.__pubsub_server__,
                     serializer: serializer}

    case handler.connect(params, socket) do
      {:ok, socket} ->
        case handler.id(socket) do
          nil                   -> {:ok, socket}
          id when is_binary(id) -> {:ok, %Socket{socket | id: id}}
          invalid               ->
            Logger.error "#{inspect handler}.id/1 returned invalid identifier #{inspect invalid}. " <>
                         "Expected nil or a string."
            :error
        end

      {:error, code} ->
        {:error, code}

      :error ->
        :error

      invalid ->
        Logger.error "#{inspect handler}.connect/2 returned invalid value #{inspect invalid}. " <>
                     "Expected {:ok, socket} or :error"
        :error
    end
  end

  @doc false
  def ws_init({socket, config}) do
    Process.flag(:trap_exit, true)
    timeout = Keyword.fetch!(config, :timeout)

    if socket.id, do: socket.endpoint.subscribe(socket.id, link: true)

    {:ok, %{socket: socket,
            channels: %{},
            channels_inverse: %{},
            serializer: socket.serializer}, timeout}
  end

  @doc false
  def ws_handle(opcode, payload, state) do
    msg = state.serializer.decode!(payload, opcode: opcode)

    case Transport.dispatch(msg, state.channels, state.socket) do
      :noreply ->
        {:ok, state}
      {:reply, reply_msg} ->
        encode_reply(reply_msg, state)
      {:joined, channel_pid, reply_msg} ->
        encode_reply(reply_msg, put(state, msg.topic, msg.ref, channel_pid))
      {:error, _reason, error_reply_msg} ->
        encode_reply(error_reply_msg, state)
    end
  end

  @doc false
  def ws_info({:EXIT, channel_pid, reason}, state) do
    case Map.get(state.channels_inverse, channel_pid) do
      nil   -> {:ok, state}
      {topic, join_ref} ->
        new_state = delete(state, topic, channel_pid)
        encode_reply(Transport.on_exit_message(topic, join_ref, reason), new_state)
    end
  end

  def ws_info({:graceful_exit, channel_pid, %Phoenix.Socket.Message{} = msg}, state) do
    new_state = delete(state, msg.topic, channel_pid)
    encode_reply(msg, new_state)
  end

  @doc false
  def ws_info(%Broadcast{event: "disconnect"}, state) do
    {:shutdown, state}
  end

  def ws_info({:socket_push, _, _encoded_payload} = msg, state) do
    format_reply(msg, state)
  end

  @doc false
  def ws_info(:garbage_collect, state) do
    :erlang.garbage_collect(self())
    {:ok, state}
  end

  def ws_info(_, state) do
    {:ok, state}
  end

  @doc false
  def ws_terminate(_reason, _state) do
    :ok
  end

  @doc false
  def ws_close(state) do
    for {pid, _} <- state.channels_inverse do
      Phoenix.Channel.Server.close(pid)
    end
  end

  defp put(state, topic, join_ref, channel_pid) do
    %{state | channels: Map.put(state.channels, topic, channel_pid),
              channels_inverse: Map.put(state.channels_inverse, channel_pid, {topic, join_ref})}
  end

  defp delete(state, topic, channel_pid) do
    case Map.fetch(state.channels, topic) do
      {:ok, ^channel_pid} ->
        %{state | channels: Map.delete(state.channels, topic),
                  channels_inverse: Map.delete(state.channels_inverse, channel_pid)}
      {:ok, _newer_pid} ->
        %{state | channels_inverse: Map.delete(state.channels_inverse, channel_pid)}
    end
  end

  defp encode_reply(reply, state) do
    format_reply(state.serializer.encode!(reply), state)
  end

  defp format_reply({:socket_push, encoding, encoded_payload}, state) do
    {:reply, {encoding, encoded_payload}, state}
  end

  defp code_reload(conn, opts, endpoint) do
    reload? = Keyword.get(opts, :code_reloader, endpoint.config(:code_reloader))
    if reload?, do: Phoenix.CodeReloader.reload!(endpoint)

    conn
  end
end
