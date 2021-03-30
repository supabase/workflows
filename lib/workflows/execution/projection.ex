defmodule Workflows.Execution.Projection do
  @moduledoc false

  alias Workflows.Activity
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

  defp do_project_single(execution, %Event{scope: []} = event) do
    with {:ok, new_state} <- do_project_single(execution.workflow, execution.state, event) do
      {:ok, %Execution{execution | state: new_state}}
    end
  end

  defp do_project_single(execution, %Event{scope: [current_scope | scope]} = event) do
    case execution.state.status do
      {:running, activity_name, children_state} ->
        activity = execution.workflow.activities[activity_name]

        case {activity, current_scope} do
          {%Activity.Parallel{}, {:branch, branch_idx}} ->
            wf = Enum.at(activity.branches, branch_idx)
            child_state = Enum.at(children_state, branch_idx)
            child_exec = Execution.create(wf, execution.ctx, child_state)

            with {:ok, new_child_exec} <-
                   do_project_single(child_exec, event |> Event.with_scope(scope)) do
              new_children_state =
                children_state
                |> List.replace_at(branch_idx, new_child_exec.state)

              new_parent_state =
                State.running(activity_name, new_children_state, execution.state.args)

              {:ok, %Execution{execution | state: new_parent_state}}
            end

          _ ->
            {:error, :invalid_scope}
        end

      state ->
        {:error, :todo, state}
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

  defp do_project_single(workflow, state, %Event{event: :parallel_started}) do
    case state.status do
      {:running, activity_name, []} ->
        activity = workflow.activities[activity_name]

        children =
          activity.branches
          |> Enum.map(fn branch ->
            State.transition_to(branch.start_at, state.args)
          end)

        {:ok, State.running(activity_name, children, state.args)}

      _ ->
        {:error, :invalid_event}
    end
  end

  defp do_project_single(_workflow, state, %Event{event: {:parallel_succeeded, result}}) do
    case state.status do
      {:running, activity_name, _} ->
        {:ok, State.completed(activity_name, result)}

      _ ->
        {:error, :invalid_event}
    end
  end

  defp do_project_single(_workflow, state, %Event{event: {:parallel_exited, args}}) do
    case state.status do
      {:completed, _} ->
        {:ok, State.succeeded(args)}

      _ ->
        {:error, :invalid_event}
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
      {:running, _, []} ->
        {:ok, state}

      _ ->
        {:error, :invalid_event}
    end
  end

  defp do_project_single(_workflow, state, %Event{event: :wait_succeeded}) do
    case state.status do
      {:running, activity_name, []} ->
        {:ok, State.completed(activity_name, state.args)}

      _ ->
        {:error, :invalid_event}
    end
  end

  defp do_project_single(_workflow, state, %Event{event: {:wait_exited, args}}) do
    case state.status do
      {:completed, _} ->
        {:ok, State.succeeded(args)}

      _ ->
        {:error, :invalid_event}
    end
  end
end
