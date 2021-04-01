defmodule Workflows.Event.MapEntered do
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.MapExited do
  defstruct [:activity, :scope, :result, :transition]
end

defmodule Workflows.Event.MapStarted do
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.MapSucceeded do
  defstruct [:activity, :scope, :result]
end

defmodule Workflows.Event.MapFailed do
  defstruct [:activity, :scope, :error]
end
