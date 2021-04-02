defmodule Workflows.Event.SucceedEntered do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.SucceedExited do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :result]
end
