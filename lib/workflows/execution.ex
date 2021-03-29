defmodule Workflows.Execution do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.Command
  alias Workflows.Event
  alias Workflows.Execution
  alias Workflows.State
  alias Workflows.Workflow

  @type t :: %__MODULE__{
          workflow: Workflow.t(),
          ctx: Activity.ctx(),
          state: State.t() | nil
        }

  @type scope_item :: {:branch, pos_integer()} | {:map_item, pos_integer()}
  @type scope :: list(scope())

  defstruct [:workflow, :ctx, :state]

  @spec create(Workflow.t(), Activity.ctx(), State.t() | nil) :: t()
  def create(workflow, ctx, state) do
    %__MODULE__{
      workflow: workflow,
      ctx: ctx,
      state: state
    }
  end

  @spec start(Workflow.t(), Activity.ctx(), Activity.args()) :: {:ok, t()} | {:error, term()}
  def start(workflow, ctx, args) do
    exec = create(workflow, ctx, nil)
    cmd = Command.start_execution(args)
    execute(exec, cmd)
  end

  @spec execute(t(), Command.t()) :: {:ok, t(), list(Event.t())} | {:error, term()}
  def execute(execution, command) do
    Execution.Behaviour.execute(execution, command)
  end

  @spec project(t(), list(Event.t())) :: {:ok, t()} | {:error, term()}
  def project(execution, events) do
    Execution.Projection.project(execution, events)
  end
end
