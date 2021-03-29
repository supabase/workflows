defmodule Workflows.Execution.Projection do
  @moduledoc false

  alias Workflows.Event
  alias Workflows.Execution
  alias Workflows.State

  @spec project(Execution.t(), list(Event.t())) :: {:ok, Execution.t()} | {:error, term()}
  def project(execution, events) do
    do_project(execution, events)
  end

  ## Private
  defp do_project(execution, []), do: {:ok, execution}

  defp do_project(execution, [event | events]) do
    with {:ok, new_execution} <- do_project_single(execution, event) do
      do_project(new_execution, events)
    end
  end

  defp do_project_single(execution, event) do
    with {:ok, new_state} <- do_project_single(execution.workflow, execution.state, event) do
      {:ok, %Execution{execution | state: new_state}}
    end
  end

  defp do_project_single(workflow, nil, %Event{event: {:execution_started, args}}) do
    {:ok, State.transition_to(workflow.start_at, args)}
  end

  defp do_project_single(_workflow, state, %Event{event: {:parallel_entered, args}}) do
    case state.status do
      {:transition_to, activity_name} -> {:ok, State.running(activity_name, args)}
      _ -> {:error, :invalid_event}
    end
  end

  defp do_project_single(_workflow, state, %Event{event: :parallel_scheduled}) do
    case state.status do
      {:running, activity_name} -> {:ok, State.running(activity_name, state.args)}
      _ -> {:error, :invalid_event}
    end
  end

  defp do_project_single(_workflow, state, %Event{event: :parallel_started}) do
    case state.status do
      {:running, activity_name} -> {:ok, State.running(activity_name, state.args)}
      _ -> {:error, :invalid_event}
    end
  end

  defp do_project_single(_workflow, state, %Event{event: {:pass_entered, args}}) do
    case state.status do
      {:transition_to, activity_name} -> {:ok, State.completed(activity_name, args)}
      _ -> {:error, :invalid_event}
    end
  end

  defp do_project_single(workflow, state, %Event{event: {:pass_exited, args}}) do
    case state.status do
      {:completed, activity_name} ->
        activity = workflow.activities[activity_name]

        case activity.transition do
          :end -> {:ok, State.succeeded(args)}
          {:next, next_activity} -> {:ok, State.transition_to(next_activity, args)}
        end

      _ ->
        {:error, :invalid_event}
    end
  end

  defp do_project_single(_workflow, state, %Event{event: {:succeed_entered, args}}) do
    case state.status do
      {:transition_to, activity_name} -> {:ok, State.completed(activity_name, args)}
      _ -> {:error, :invalid_event}
    end
  end

  defp do_project_single(_workflow, state, %Event{event: {:succeed_exited, args}}) do
    case state.status do
      {:completed, _activity_name} ->
        {:ok, State.succeeded(args)}

      _ ->
        {:error, :invalid_event}
    end
  end

  defp do_project_single(_workflow, state, %Event{event: {:wait_entered, args}}) do
    case state.status do
      {:transition_to, activity_name} -> {:ok, State.running(activity_name, args)}
      _ -> {:error, :invalid_event}
    end
  end

  defp do_project_single(_workflow, state, %Event{event: {:wait_started, _duration}}) do
    case state.status do
      {:running, _} ->
        {:ok, state}

      _ ->
        {:error, :invalid_event}
    end
  end

  defp do_project_single(_workflow, state, %Event{event: :wait_succeeded}) do
    case state.status do
      {:running, activity_name} ->
        {:ok, State.completed(activity_name, state.args)}

      _ ->
        {:error, :invalid_event}
    end
  end

  defp do_project_single(_workflow, state, %Event{event: {:wait_exited, args}}) do
    case state.status do
      {:running, _activity_name} ->
        {:ok, State.succeeded(args)}

      _ ->
        {:error, :invalid_event}
    end
  end
end
