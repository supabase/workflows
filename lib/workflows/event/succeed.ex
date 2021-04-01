defmodule Workflows.Event.SucceedEntered do
  @type t :: struct()
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.SucceedExited do
  @type t :: struct()
  defstruct [:activity, :scope, :result]
end
