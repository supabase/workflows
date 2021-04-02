defmodule Workflows.Event.TaskEntered do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.TaskExited do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :result, :transition]
end

defmodule Workflows.Event.TaskStarted do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :resource, :args]
end

defmodule Workflows.Event.TaskSucceeded do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :result]
end

defmodule Workflows.Event.TaskFailed do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :error]
end
