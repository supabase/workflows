defmodule Workflows.Event.MapEntered do
  @type t :: struct()
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.MapExited do
  @type t :: struct()
  defstruct [:activity, :scope, :result, :transition]
end

defmodule Workflows.Event.MapStarted do
  @type t :: struct()
  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.MapSucceeded do
  @type t :: struct()
  defstruct [:activity, :scope, :result]
end

defmodule Workflows.Event.MapFailed do
  @type t :: struct()
  defstruct [:activity, :scope, :error]
end
