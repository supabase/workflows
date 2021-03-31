defmodule Workflows.State.Wait do
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

  defp do_execute(%State.Wait{} = state, %Activity.Wait{} = activity, ctx) do
    case state.inner do
      {:before_enter, state_args} ->
        Activity.enter(activity, ctx, state_args)

      {:running, _state_args, effective_args} ->
        Activity.Wait.start_wait(activity, ctx, effective_args)

      {:waiting, state_args, effective_args} ->
        # Need command to move forward
        {:ok, :no_event}

      {:wait_finished, state_args, effective_args} ->
        Activity.exit(activity, ctx, state_args, effective_args)
    end
  end

  defp do_execute_command(
         %State.Wait{} = state,
         %Activity.Wait{} = activity,
         ctx,
         %Command.FinishWaiting{} = cmd
       ) do
    case state.inner do
      {:waiting, _, _} ->
        Activity.Wait.finish_waiting(activity, ctx)

      _ ->
        {:error, :invalid_command, cmd}
    end
  end

  defp do_execute_command(%State.Wait{}, %Activity.Wait{}, _ctx, cmd) do
    {:error, :invalid_command, cmd}
  end

  defp do_project(%State.Wait{} = state, %Event.WaitEntered{} = event) do
    case state.inner do
      {:before_enter, state_args} ->
        new_state = %State.Wait{state | inner: {:running, state_args, event.args}}
        {:stay, new_state}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project(%State.Wait{} = state, %Event.WaitStarted{} = event) do
    case state.inner do
      {:running, state_args, effective_args} ->
        new_state = %State.Wait{state | inner: {:waiting, state_args, effective_args}}
        {:stay, new_state}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project(%State.Wait{} = state, %Event.WaitSucceeded{} = event) do
    case state.inner do
      {:waiting, state_args, effective_args} ->
        new_state = %State.Wait{state | inner: {:wait_finished, state_args, effective_args}}
        {:stay, new_state}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project(%State.Wait{} = state, %Event.WaitExited{} = event) do
    case state.inner do
      {:wait_finished, _state_args, _args} ->
        {:transition, event.transition, event.result}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project(_state, event) do
    {:error, :invalid_event, event}
  end
end
