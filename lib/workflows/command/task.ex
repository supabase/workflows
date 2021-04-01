defmodule Workflows.Command.CompleteTask do
  @type t :: struct()
  defstruct [:activity, :scope, :result]
end

defmodule Workflows.Command.FailTask do
  @type t :: struct()
  defstruct [:activity, :scope, :error]
end
