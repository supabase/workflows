defmodule Workflows.Event.SucceedEntered do
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.SucceedExited do
  defstruct [:activity, :scope, :result]
end
