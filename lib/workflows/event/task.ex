defmodule Workflows.Event.TaskEntered do
  @type t :: struct()
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.TaskExited do
  @type t :: struct()
  defstruct [:activity, :scope, :result, :transition]
end

defmodule Workflows.Event.TaskStarted do
  @type t :: struct()
  defstruct [:activity, :scope, :resource, :args]
end

defmodule Workflows.Event.TaskSucceeded do
  @type t :: struct()
  defstruct [:activity, :scope, :result]
end

defmodule Workflows.Event.TaskFailed do
  @type t :: struct()
  defstruct [:activity, :scope, :error]
end
