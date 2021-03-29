defmodule Workflows.Command do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.Execution

  @type command ::
          {:start_execution, Activity.args()}
          | :fire_timer
          | :start_parallel

  @type t :: %__MODULE__{
          command: command(),
          scope: Execution.scope()
        }

  defstruct [:command, :scope]

  @spec create(command(), Execution.scope()) :: t()
  def create(command, scope) do
    %__MODULE__{
      command: command,
      scope: scope
    }
  end

  @spec start_execution(Activity.args()) :: t()
  def start_execution(args) do
    create({:start_execution, args}, [])
  end

  @spec fire_timer() :: t()
  def fire_timer() do
    create(:fire_timer, [])
  end

  @spec start_parallel() :: t()
  def start_parallel() do
    create(:start_parallel, [])
  end
end
