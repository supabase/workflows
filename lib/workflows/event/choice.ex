defmodule Workflows.Event.ChoiceEntered do
  @type t :: struct()
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.ChoiceExited do
  @type t :: struct()
  defstruct [:activity, :scope, :result, :transition]
end
