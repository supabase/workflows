defmodule Workflows.Event.TaskEntered do
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.TaskExited do
  defstruct [:activity, :scope, :result, :transition]
end

defmodule Workflows.Event.TaskStarted do
  defstruct [:activity, :scope, :resource, :args]
end

defmodule Workflows.Event.TaskSucceeded do
  defstruct [:activity, :scope, :result]
end

defmodule Workflows.Event.TaskFailed do
  defstruct [:activity, :scope, :error]
end
