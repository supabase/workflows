defmodule Workflows.Execution do
  @moduledoc false

  alias Workflows.{Activity, Command, Event, State, Workflow}

  @type t :: %__MODULE__{
          workflow: Workflow.t(),
          state: State.t(),
          ctx: Activity.ctx()
        }

  @type scope ::
          {:branch, pos_integer()}
          | {:item, pos_integer()}

  @type execution_result ::
          {:continue, t(), list(Event.t())} | {:succeed, Activity.args(), list(Event.t())}

  defstruct [:workflow, :ctx, :state]

  @spec start(Workflow.t(), Activity.ctx(), Activity.args()) ::
          execution_result() | {:error, term()}
  def start(workflow, ctx, args) do
    with {:ok, execution} <- create(workflow, ctx, args) do
      started = %Event.ExecutionStarted{args: args, ctx: ctx}
      do_resume(execution, [started])
    end
  end

  @spec resume(t(), Command.t()) :: execution_result() | {:error, term()}
  def resume(execution, cmd) do
    do_resume(execution, cmd, [])
  end

  @spec recover(Workflow.t(), list(Event.t())) :: execution_result() | {:error, term()}
  def recover(workflow, events) do
    do_recover(workflow, events)
  end

  ## Private
  defp create(workflow, ctx, args) do
    with {:ok, starting} <- Workflow.starting_activity(workflow) do
      state = State.create(starting, args)

      execution = %__MODULE__{
        workflow: workflow,
        state: state,
        ctx: ctx
      }

      {:ok, execution}
    end
  end

  defp update_state(execution, new_state) do
    %__MODULE__{execution | state: new_state}
  end

  defp do_resume(execution, cmd, events_acc) do
    execute_result = Workflow.execute(execution.workflow, execution.state, execution.ctx, cmd)
    continue_resume(execution, events_acc, execute_result)
  end

  defp do_resume(execution, events_acc) do
    execute_result = Workflow.execute(execution.workflow, execution.state, execution.ctx)
    continue_resume(execution, events_acc, execute_result)
  end

  defp continue_resume(execution, events_acc, execute_result) do
    case execute_result do
      {:ok, :no_event} ->
        {:continue, execution, Enum.reverse(events_acc)}

      {:ok, event} ->
        case Workflow.project(execution.workflow, execution.state, event) do
          {:continue, new_state} ->
            new_execution = update_state(execution, new_state)
            do_resume(new_execution, [event | events_acc])

          {:succeed, result} ->
            {:succeed, result, Enum.reverse([event | events_acc])}
        end
    end
  end

  defp do_recover(workflow, [%Event.ExecutionStarted{args: args, ctx: ctx} | events]) do
    with {:ok, execution} <- create(workflow, ctx, args) do
      case Workflow.project(execution.workflow, execution.state, events) do
        {:continue, new_state} ->
          new_execution = update_state(execution, new_state)
          do_resume(new_execution, [])

        {:succeed, result} ->
          {:succeed, result, []}
      end
    end
  end
end
