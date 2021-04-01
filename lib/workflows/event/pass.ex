defmodule Workflows.Event.PassEntered do
  @type t :: struct()
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.PassExited do
  @type t :: struct()
  defstruct [:activity, :scope, :result, :transition]
end
