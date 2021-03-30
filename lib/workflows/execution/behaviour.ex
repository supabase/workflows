defmodule Workflows.Execution.Behaviour do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.Command
  alias Workflows.Event
  alias Workflows.Execution

  @spec execute(Execution.t(), Command.t()) ::
          {:ok, Execution.t(), list(Event.t())} | {:error, term()}
  def execute(execution, command) do
    with {:ok, events} <- do_execute(execution.workflow, execution.state, command),
         {:ok, new_execution} <- Execution.project(execution, events) do
      consume_execution(new_execution, events, [])
    end
  end

  ## Private

  defp do_execute(_workflow, nil, %Command{command: {:start_execution, args}, scope: []}) do
    {:ok, [Event.execution_started(args)]}
  end

  defp do_execute(_workflow, _state, %Command{command: {:start_execution, _args}}) do
    {:error, :invalid_command}
  end

  defp do_execute(_workflow, _state, %Command{command: :fire_timer, scope: scope}) do
    {:ok, [Event.create(:wait_succeeded, scope)]}
  end

  defp do_execute(_workflow, _state, command) do
    {:error, :unknown_command, command}
  end

  defp consume_execution(execution, events_acc, scope) do
    case execution.state.status do
      {:running, _, []} ->
        {:ok, execution, events_acc}

      :succeeded ->
        case scope do
          [] -> {:ok, execution, [Event.execution_succeeded(execution.state.args) | events_acc]}
          _ -> {:ok, execution, events_acc}
        end

      :failed ->
        {:ok, execution, events_acc}

      {:running, activity_name, children_state} ->
        if all_succeeded?(children_state) do
          activity = execution.workflow.activities[activity_name]
          result = children_state |> Enum.map(fn state -> state.args end)

          with {:ok, exit_events} <-
                 Activity.exit(activity, execution.ctx, execution.state.args, result),
               {:ok, new_execution} <- Execution.project(execution, exit_events) do
            consume_execution(new_execution, Enum.reverse(exit_events) ++ events_acc, scope)
          end
        else
          with {:ok, children_events} <-
                 consume_children_execution(execution, activity_name, children_state, scope),
               {:ok, new_execution} <- Execution.project(execution, Enum.reverse(children_events)) do
            case children_events do
              [] ->
                {:ok, new_execution, events_acc}

              _ ->
                consume_execution(new_execution, children_events ++ events_acc, scope)
            end
          end
        end

      {:completed, activity_name} ->
        # Exit, then transition or terminate
        # TODO: need to keep state arguments around
        activity = execution.workflow.activities[activity_name]

        with {:ok, exit_events} <-
               Activity.exit(activity, execution.ctx, execution.state.args, execution.state.args),
             {:ok, new_execution} <- Execution.project(execution, exit_events) do
          consume_execution(new_execution, Enum.reverse(exit_events) ++ events_acc, scope)
        end

      {:transition_to, next_activity_name} ->
        next_activity = execution.workflow.activities[next_activity_name]

        with {:ok, transition_events} <-
               Activity.enter(next_activity, execution.ctx, execution.state.args),
             {:ok, new_execution} <- Execution.project(execution, transition_events) do
          consume_execution(new_execution, Enum.reverse(transition_events) ++ events_acc, scope)
        end
    end
  end

  defp consume_children_execution(parent_execution, activity_name, children_state, scope) do
    activity = parent_execution.workflow.activities[activity_name]

    children_state
    |> Enum.with_index()
    |> Enum.map(fn {child_state, child_idx} ->
      wf = Enum.at(activity.branches, child_idx)
      child_exec = Execution.create(wf, parent_execution.ctx, child_state)
      local_scope = [{:branch, child_idx}]
      new_scope = scope ++ local_scope

      with {:ok, _, events} <- consume_execution(child_exec, [], new_scope) do
        events_with_scope = events |> Enum.map(fn e -> Event.with_scope(e, new_scope) end)
        {:ok, events_with_scope}
      end
    end)
    |> Enum.reduce({:ok, []}, fn
      {:ok, events}, {:ok, events_acc} -> {:ok, events ++ events_acc}
      _, {:error, err} -> {:error, err}
      {:error, err}, _ -> {:error, err}
    end)
  end

  defp all_succeeded?(children_state) do
    children_state
    |> Enum.all?(fn state -> state.status == :succeeded end)
  end
end
