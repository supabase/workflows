defmodule Workflows.Event.MapEntered do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.MapExited do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :result, :transition]
end

defmodule Workflows.Event.MapStarted do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :args]
end

defmodule Workflows.Event.MapSucceeded do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :result]
end

defmodule Workflows.Event.MapFailed do
  @moduledoc false

  @type t :: struct()

  defstruct [:activity, :scope, :error]
end
