defmodule Workflows.Event.FailEntered do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.FailExited do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :error]
end
