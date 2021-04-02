defmodule Workflows.Event.WaitEntered do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.WaitExited do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :result, :transition]
end

defmodule Workflows.Event.WaitStarted do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :wait]
end

defmodule Workflows.Event.WaitSucceeded do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope]
end
