defmodule Workflows.Event.FailEntered do
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.FailExited do
  defstruct [:activity, :scope, :error]
end
