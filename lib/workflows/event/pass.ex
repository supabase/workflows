defmodule Workflows.Event.PassEntered do
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.PassExited do
  defstruct [:activity, :scope, :result, :transition]
end
