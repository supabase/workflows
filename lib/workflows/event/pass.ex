defmodule Workflows.Event.PassEntered do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.PassExited do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :result, :transition]
end
