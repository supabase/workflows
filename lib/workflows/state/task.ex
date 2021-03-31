defmodule Workflows.State.Task do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.Command
  alias Workflows.Event
  alias Workflows.State

  use State

  def execute(state, activity, ctx), do: do_execute(state, activity, ctx)
  def execute(state, activity, ctx, cmd), do: do_execute_command(state, activity, ctx, cmd)
  def project(state, _activity, event), do: do_project(state, event)

  ## Private

  defp do_execute(%State.Task{} = state, %Activity.Task{} = activity, ctx) do
    case state.inner do
      {:before_enter, state_args} ->
        Activity.enter(activity, ctx, state_args)

      {:running, _state_args, effective_args} ->
        Activity.Task.start_task(activity, ctx, effective_args)

      {:waiting_response, state_args, effective_args} ->
        # Need command to move forward
        {:ok, :no_event}

      {:task_finished, state_args, result} ->
        Activity.exit(activity, ctx, state_args, result)
    end
  end

  defp do_execute_command(
         %State.Task{} = state,
         %Activity.Task{} = activity,
         ctx,
         %Command.CompleteTask{} = cmd
       ) do
    case state.inner do
      {:waiting_response, _, _} ->
        Activity.Task.complete_task(activity, ctx, cmd.result)

      _ ->
        {:error, :invalid_command, cmd}
    end
  end

  defp do_execute_command(%State.Task{}, %Activity.Task{}, _ctx, cmd) do
    {:error, :invalid_command, cmd}
  end

  defp do_project(%State.Task{} = state, %Event.TaskEntered{} = event) do
    case state.inner do
      {:before_enter, state_args} ->
        new_state = %State.Task{state | inner: {:running, state_args, event.args}}
        {:stay, new_state}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project(%State.Task{} = state, %Event.TaskStarted{} = event) do
    case state.inner do
      {:running, state_args, effective_args} ->
        new_state = %State.Task{state | inner: {:waiting_response, state_args, effective_args}}
        {:stay, new_state}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project(%State.Task{} = state, %Event.TaskSucceeded{} = event) do
    case state.inner do
      {:waiting_response, state_args, _} ->
        new_state = %State.Task{state | inner: {:task_finished, state_args, event.result}}
        {:stay, new_state}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project(%State.Task{} = state, %Event.TaskExited{} = event) do
    case state.inner do
      {:task_finished, _state_args, _args} ->
        {:transition, event.transition, event.result}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project(_state, event) do
    {:error, :invalid_event, event}
  end
end
