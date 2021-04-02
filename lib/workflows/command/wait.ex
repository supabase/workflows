defmodule Workflows.Command.FinishWaiting do
  @moduledoc false
  @type t :: struct()
  defstruct [:activity, :scope]
end
