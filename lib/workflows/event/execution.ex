defmodule Workflows.Event.ExecutionStarted do
  @moduledoc false

  @type t :: struct()

  defstruct [:args]
end
