defmodule KuberaAdmin.V1.FallbackController do
  use KuberaAdmin, :controller
  import KuberaAdmin.V1.ErrorHandler

  def not_found(conn, _attrs) do
    handle_error(conn, :endpoint_not_found)
  end
end
