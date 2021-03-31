defmodule Workflows.Command.CompleteTask do
  defstruct [:activity, :scope, :result]
end

defmodule Workflows.Command.FailTask do
  defstruct [:activity, :scope, :error]
end
