defmodule Workflows.State.Task do
  @moduledoc false

  alias Workflows.{Activity, Catcher, Command, Event, Retrier, State}

  use State

  def execute(state, activity, ctx), do: do_execute(state, activity, ctx)
  def execute(state, activity, ctx, cmd), do: do_execute_command(state, activity, ctx, cmd)
  def project(state, activity, event), do: do_project(state, activity, event)

  ## Private

  defp do_execute(%State.Task{} = state, %Activity.Task{} = activity, ctx) do
    case state.inner do
      {:before_enter, state_args} ->
        Activity.enter(activity, ctx, state_args)

      {:running, _state_args, effective_args} ->
        Activity.Task.start_task(activity, ctx, effective_args)

      {:waiting_response, _state_args, _effective_args, _retriers_state} ->
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
      {:waiting_response, _state_args, _effective_args, _retriers_state} ->
        Activity.Task.complete_task(activity, ctx, cmd.result)

      _ ->
        {:error, :invalid_command, cmd}
    end
  end

  defp do_execute_command(
         %State.Task{} = state,
         %Activity.Task{} = activity,
         ctx,
         %Command.FailTask{} = cmd
       ) do
    case state.inner do
      {:waiting_response, _state_args, effective_args, retriers_state} ->
        case match_retriers(retriers_state, activity.retry, cmd.error) do
          {:retry, retrier, retry_count} ->
            wait = Retrier.wait_seconds(retrier, retry_count)
            Activity.Task.retry_task(activity, ctx, effective_args, cmd.error, wait)

          :max_attempts_reached ->
            Activity.Task.fail_task(activity, ctx, cmd.error)

          :no_match ->
            nil
        end

      _ ->
        {:error, :invalid_command, cmd}
    end
  end

  defp do_execute_command(%State.Task{}, %Activity.Task{}, _ctx, cmd) do
    {:error, :invalid_command, cmd}
  end

  defp do_project(%State.Task{} = state, _activity, %Event.TaskEntered{} = event) do
    case state.inner do
      {:before_enter, state_args} ->
        new_state = %State.Task{state | inner: {:running, state_args, event.args}}
        {:stay, new_state}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project(%State.Task{} = state, activity, %Event.TaskStarted{} = event) do
    case state.inner do
      {:running, state_args, effective_args} ->
        retriers_state = Enum.map(activity.retry, fn _ -> 0 end)

        new_state = %State.Task{
          state
          | inner: {:waiting_response, state_args, effective_args, retriers_state}
        }

        {:stay, new_state}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project(%State.Task{} = state, _activity, %Event.TaskSucceeded{} = event) do
    case state.inner do
      {:waiting_response, state_args, _effective_args, _retriers_state} ->
        new_state = %State.Task{state | inner: {:task_finished, state_args, event.result}}
        {:stay, new_state}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project(%State.Task{} = state, activity, %Event.TaskRetried{} = event) do
    case state.inner do
      {:waiting_response, state_args, effective_args, retriers_state} ->
        case update_retriers_state(retriers_state, activity.retry, event.error, []) do
          {:ok, new_retriers_state} ->
            new_inner = {:waiting_response, state_args, effective_args, new_retriers_state}
            new_state = %State.Task{state | inner: new_inner}
            {:stay, new_state}

          {:error, _reason} ->
            {:error, :invalid_event, event}
        end

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project(%State.Task{} = state, activity, %Event.TaskFailed{} = event) do
    case state.inner do
      {:waiting_response, _state_args, _effective_args, _retriers_state} ->
        case Enum.find(activity.catch, fn c -> Catcher.matches?(c, event.error) end) do
          nil ->
            {:fail, event.error}

          catcher ->
            # TODO: add result path here
            error = %{"Name" => event.error.name, "Cause" => event.error.cause}
            {:transition, {:next, catcher.next}, error}
        end

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project(%State.Task{} = state, _activity, %Event.TaskExited{} = event) do
    case state.inner do
      {:task_finished, _state_args, _args} ->
        {:transition, event.transition, event.result}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project(_state, _activity, event) do
    {:error, :invalid_event, event}
  end

  defp match_retriers([], _retriers, _error) do
    :no_match
  end

  defp match_retriers([state | states], [retrier | retriers], error) do
    if Retrier.matches?(retrier, error) do
      if state < retrier.max_attempts do
        {:retry, retrier, state}
      else
        :max_attempts_reached
      end
    else
      match_retriers(states, retriers, error)
    end
  end

  defp update_retriers_state([], [], _error, _new_states) do
    {:error, :expected_matching_retrier}
  end

  defp update_retriers_state([state | states], [retrier | retriers], error, new_states) do
    if Retrier.matches?(retrier, error) do
      new_state = state + 1
      new_states = Enum.reverse(new_states) ++ [new_state | states]
      {:ok, new_states}
    else
      update_retriers_state(states, retriers, error, [state | new_states])
    end
  end
end
