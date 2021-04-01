defmodule Workflows.Event.FailEntered do
  @type t :: struct()
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.FailExited do
  @type t :: struct()
  defstruct [:activity, :scope, :error]
end
