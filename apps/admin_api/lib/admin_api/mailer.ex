defmodule AdminAPI.Mailer do
  @moduledoc """
  The module that sends emails.
  """
  use Bamboo.Mailer, otp_app: :admin_api
end
