defmodule Workflows.Event.ParallelEntered do
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.ParallelExited do
  defstruct [:activity, :scope, :result, :transition]
end

defmodule Workflows.Event.ParallelStarted do
  defstruct [:activity, :scope, :resource, :args]
end

defmodule Workflows.Event.ParallelSucceeded do
  defstruct [:activity, :scope, :result]
end

defmodule Workflows.Event.ParallelFailed do
  defstruct [:activity, :scope, :error]
end
