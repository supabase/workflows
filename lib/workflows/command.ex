defmodule Workflows.Command do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.Execution

  @type command ::
          {:start_execution, Activity.args()}
          | :fire_timer

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

  def with_scope(command, scope) do
    %__MODULE__{command | scope: scope}
  end

  @spec start_execution(Activity.args()) :: t()
  def start_execution(args) do
    create({:start_execution, args}, [])
  end

  @spec fire_timer() :: t()
  def fire_timer() do
    create(:fire_timer, [])
  end
end
