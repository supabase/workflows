defmodule Workflows.Event.ChoiceEntered do
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.ChoiceExited do
  defstruct [:activity, :scope, :result, :transition]
end
