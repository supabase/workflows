defmodule Workflows.State.Fail do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.Event
  alias Workflows.State

  use State

  def execute(state, activity, ctx), do: do_execute(state, activity, ctx)
  def project(state, _activity, event), do: do_project(state, event)

  ## Private

  defp do_execute(%State.Fail{} = state, %Activity.Fail{} = activity, ctx) do
    case state.inner do
      {:before_enter, state_args} ->
        Activity.enter(activity, ctx, state_args)

      {:running, state_args, effective_args} ->
        Activity.exit(activity, ctx, state_args, effective_args)
    end
  end

  defp do_project(%State.Fail{} = state, %Event.FailEntered{} = event) do
    case state.inner do
      {:before_enter, state_args} ->
        new_state = %State.Fail{state | inner: {:running, state_args, event.args}}
        {:stay, new_state}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project(%State.Fail{} = state, %Event.FailExited{} = event) do
    case state.inner do
      {:running, _state_args, _args} ->
        {:fail, event.error}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project(_state, event) do
    {:error, :invalid_event, event}
  end
end
