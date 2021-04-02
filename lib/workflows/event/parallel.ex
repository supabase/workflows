defmodule Workflows.Event.ParallelEntered do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.ParallelExited do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :result, :transition]
end

defmodule Workflows.Event.ParallelStarted do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.ParallelSucceeded do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :result]
end

defmodule Workflows.Event.ParallelFailed do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :error]
end
