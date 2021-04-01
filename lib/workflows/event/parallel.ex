defmodule Workflows.Event.ParallelEntered do
  @type t :: struct()
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.ParallelExited do
  @type t :: struct()
  defstruct [:activity, :scope, :result, :transition]
end

defmodule Workflows.Event.ParallelStarted do
  @type t :: struct()
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.ParallelSucceeded do
  @type t :: struct()
  defstruct [:activity, :scope, :result]
end

defmodule Workflows.Event.ParallelFailed do
  @type t :: struct()
  defstruct [:activity, :scope, :error]
end
