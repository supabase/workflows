defmodule Workflows.Event.WaitEntered do
  @type t :: struct()
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.WaitExited do
  @type t :: struct()
  defstruct [:activity, :scope, :result, :transition]
end

defmodule Workflows.Event.WaitStarted do
  @type t :: struct()
  defstruct [:activity, :scope, :wait]
end

defmodule Workflows.Event.WaitSucceeded do
  @type t :: struct()
  defstruct [:activity, :scope]
end
