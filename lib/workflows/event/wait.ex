defmodule Workflows.Event.WaitEntered do
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.WaitExited do
  defstruct [:activity, :scope, :result, :transition]
end

defmodule Workflows.Event.WaitStarted do
  defstruct [:activity, :scope, :wait]
end

defmodule Workflows.Event.WaitSucceeded do
  defstruct [:activity, :scope]
end
