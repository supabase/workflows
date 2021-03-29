defmodule Workflows.Execution.Behaviour do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.Command
  alias Workflows.Event
  alias Workflows.Execution

  @spec execute(Execution.t(), Command.t()) :: {:ok, Execution.t(), list(Event.t())} | {:error, term()}
  def execute(execution, command) do
    with {:ok, events} <- do_execute(execution.workflow, execution.state, command),
         {:ok, new_execution} <- Execution.project(execution, events) do
      consume_execution(new_execution, events)
    end
  end

  ## Private

  defp do_execute(_workflow, nil, %Command{command: {:start_execution, args}}) do
    {:ok, [Event.execution_started(args)]}
  end

  defp do_execute(_workflow, _state, %Command{command: {:start_execution, _args}}) do
    {:error, :invalid_command}
  end

  defp do_execute(_workflow, _state, %Command{command: :fire_timer}) do
    {:ok, [Event.create(:wait_succeeded, [])]}
  end

  defp do_execute(_workflow, _state, %Command{command: :start_parallel}) do
    {:ok, [Event.create(:parallel_started, [])]}
  end

  defp do_execute(_workflow, _state, command) do
    {:error, :unknown_command, command}
  end

  defp consume_execution(execution, events_acc) do
    case execution.state.status do
      {:running, _} ->
        # Does it have sub-workflows? Then try to consume them
        {:ok, execution, events_acc}
      :succeeded -> {:ok, execution, events_acc}
      :failed -> {:ok, execution, events_acc}
      {:completed, activity_name} ->
        # Exit, then transition or terminate
        # TODO: need to keep state arguments around
        activity = execution.workflow.activities[activity_name]
        with {:ok, exit_events} <- Activity.exit(activity, execution.ctx, execution.state.args, execution.state.args),
             {:ok, new_execution} <- Execution.project(execution, exit_events) do
          consume_execution(new_execution, Enum.reverse(exit_events) ++ events_acc)
        end
      {:transition_to, next_activity_name} ->
        next_activity = execution.workflow.activities[next_activity_name]
        with {:ok, transition_events} <- Activity.enter(next_activity, execution.ctx, execution.state.args),
             {:ok, new_execution} <- Execution.project(execution, transition_events) do
          consume_execution(new_execution, Enum.reverse(transition_events) ++ events_acc)
        end
    end
  end

end
