defmodule LocalLedger.Scheduler do
  @moduledoc false
  use Quantum.Scheduler, otp_app: :local_ledger
end
