defmodule Workflows.Execution do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.Command
  alias Workflows.Event
  alias Workflows.State
  alias Workflows.Workflow

  @type scope ::
          {:branch, pos_integer()}
          | {:item, pos_integer()}

  @type execution_result ::
          {:continue, State.t(), list(Event.t())} | {:succeed, Activity.args(), list(Event.t())}

  @spec start(Workflow.t(), Activity.ctx(), Activity.args()) ::
          execution_result() | {:error, term()}
  def start(workflow, ctx, args) do
    with {:ok, starting} <- Workflow.starting_activity(workflow) do
      state = State.create(starting, args)
      started = %Event.ExecutionStarted{args: args}
      do_resume(workflow, state, ctx, [started])
    end
  end

  @spec resume(Workflow.t(), State.t(), Activity.ctx()) :: execution_result() | {:error, term()}
  def resume(workflow, state, ctx) do
    do_resume(workflow, state, ctx, [])
  end

  @spec resume(Workflow.t(), State.t(), Activity.ctx(), Command.t()) ::
          execution_result() | {:error, term()}
  def resume(workflow, state, ctx, cmd) do
    do_resume(workflow, state, ctx, cmd, [])
  end

  ## Private

  defp do_resume(workflow, state, ctx, cmd, events_acc) do
    execute_result = Workflow.execute(workflow, state, ctx, cmd)
    continue_resume(workflow, state, ctx, events_acc, execute_result)
  end

  defp do_resume(workflow, state, ctx, events_acc) do
    execute_result = Workflow.execute(workflow, state, ctx)
    continue_resume(workflow, state, ctx, events_acc, execute_result)
  end

  defp continue_resume(workflow, state, ctx, events_acc, execute_result) do
    case execute_result do
      {:ok, :no_event} ->
        {:continue, state, Enum.reverse(events_acc)}

      {:ok, event} ->
        case Workflow.project(workflow, state, event) do
          {:continue, new_state} ->
            do_resume(workflow, new_state, ctx, [event | events_acc])

          {:succeed, result} ->
            {:succeed, result, Enum.reverse([event | events_acc])}
        end
    end
  end
end
