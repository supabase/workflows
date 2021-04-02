defmodule Workflows.Command.CompleteTask do
  @moduledoc false
  @type t :: struct()
  defstruct [:activity, :scope, :result]
end

defmodule Workflows.Command.FailTask do
  @moduledoc false
  @type t :: struct()
  defstruct [:activity, :scope, :error]
end
