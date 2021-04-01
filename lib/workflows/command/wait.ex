defmodule Workflows.Command.FinishWaiting do
  @type t :: struct()
  defstruct [:activity, :scope]
end
