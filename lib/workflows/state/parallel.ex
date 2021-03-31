defmodule Workflows.State.Parallel do
  @moduledoc false

  alias Workflows.Activity
  alias Workflows.Command
  alias Workflows.Event
  alias Workflows.State
  alias Workflows.Workflow

  use State

  def execute(state, activity, ctx), do: do_execute(state, activity, ctx)
  def execute(state, activity, ctx, cmd), do: do_execute_command(state, activity, ctx, cmd)
  def project(state, activity, event), do: do_project(state, activity, event)

  ## Private

  defp do_execute(%State.Parallel{} = state, %Activity.Parallel{} = activity, ctx) do
    case state.inner do
      {:before_enter, state_args} ->
        Activity.enter(activity, ctx, state_args)

      {:starting, _state_args, effective_args} ->
        Activity.Parallel.start_parallel(activity, ctx, effective_args)

      {:running, _state_args, _effective_args, children} ->
        case execute_child(activity.branches, children, 0, ctx) do
          {:ok, :no_event} ->
            check_all_children_completed(activity, ctx, children)

          {:ok, event} ->
            {:ok, event}
        end

      {:parallel_finished, state_args, result} ->
        Activity.exit(activity, ctx, state_args, result)
    end
  end

  defp do_execute_command(%State.Parallel{} = state, %Activity.Parallel{} = activity, ctx, cmd) do
    case state.inner do
      {:running, _state_args, _effective_args, children} ->
        case Command.pop_scope(cmd) do
          {{:branch, branch_index}, cmd} ->
            child_state =
              Enum.zip(activity.branches, children)
              |> Enum.at(branch_index)

            case child_state do
              {branch, {:continue, child_state}} ->
                with {:ok, event} <- Workflow.execute(branch, child_state, ctx, cmd) do
                  case event do
                    :no_event ->
                      {:ok, :no_event}

                    event ->
                      {:ok, event |> Event.push_scope({:branch, branch_index})}
                  end
                end

              _ ->
                {:error, :invalid_command, cmd}
            end

          _ ->
            {:error, :invalid_command, cmd}
        end

      _ ->
        {:error, :invalid_command, cmd}
    end
  end

  defp do_project(%State.Parallel{} = state, activity, event) do
    case event.scope do
      [] -> do_project_this_scope(state, activity, event)
      _ -> do_project_scoped(state, activity, event)
    end
  end

  defp do_project_this_scope(%State.Parallel{} = state, _activity, %Event.ParallelEntered{} = event) do
    case state.inner do
      {:before_enter, state_args} ->
        new_state = %State.Parallel{state | inner: {:starting, state_args, event.args}}
        {:stay, new_state}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project_this_scope(%State.Parallel{} = state, activity, %Event.ParallelStarted{} = event) do
    case state.inner do
      {:starting, state_args, effective_args} ->
        with {:ok, children} = create_children_starting_state(activity.branches, effective_args) do
          new_state = %State.Parallel{
            state
            | inner: {:running, state_args, effective_args, children}
          }

          {:stay, new_state}
        end

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project_this_scope(%State.Parallel{} = state, _activity, %Event.ParallelSucceeded{} = event) do
    case state.inner do
      {:running, state_args, _, _children} ->
        new_state = %State.Parallel{state | inner: {:parallel_finished, state_args, event.result}}
        {:stay, new_state}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project_this_scope(%State.Parallel{} = state, _activity, %Event.ParallelExited{} = event) do
    case state.inner do
      {:parallel_finished, _state_args, _args} ->
        {:transition, event.transition, event.result}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project_this_scope(_state, _activity, event) do
    {:error, :invalid_event, event}
  end

  defp do_project_scoped(%State.Parallel{} = state, activity, event) do
    case state.inner do
      {:running, state_args, effective_args, children} ->
        case Event.pop_scope(event) do
          {{:branch, branch_index}, event} ->
            child_state =
              Enum.zip(activity.branches, children)
              |> Enum.at(branch_index)

            case child_state do
              {branch, {:continue, child_state}} ->
                new_child_state = project_child(child_state, branch, event)
                new_children = List.replace_at(children, branch_index, new_child_state)

                new_state = %State.Parallel{
                  state
                  | inner: {:running, state_args, effective_args, new_children}
                }

                {:stay, new_state}

              _ ->
                # Wrong branch index
                {:error, :invalid_event, event}
            end

          {_, _} ->
            {:error, :invalid_event, event}
        end

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp create_children_starting_state(branches, args) do
    create_children_starting_state(branches, args, [])
  end

  defp create_children_starting_state([], _args, children) do
    {:ok, Enum.reverse(children)}
  end

  defp create_children_starting_state([branch | branches], args, children) do
    with {:ok, activity} <- Workflow.starting_activity(branch) do
      state = State.create(activity, args)
      create_children_starting_state(branches, args, [{:continue, state} | children])
    end
  end

  # Finished executing all children
  defp execute_child([], [], _branch_index, ctx), do: {:ok, :no_event}

  defp execute_child([branch | branches], [{:continue, child} | children], branch_index, ctx) do
    with {:ok, activity} <- Workflow.activity(branch, child.activity),
         {:ok, event} <- State.execute(child, activity, ctx) do
      case event do
        :no_event ->
          execute_child(branches, children, branch_index + 1, ctx)

        event ->
          {:ok, event |> Event.push_scope({:branch, branch_index})}
      end
    end
  end

  defp execute_child([_branch | branches], [{:succeed, _result} | children], branch_index, ctx) do
    execute_child(branches, children, branch_index + 1, ctx)
  end

  defp project_child(child_state, branch, event) do
    Workflow.project(branch, child_state, event)
  end

  defp check_all_children_completed(activity, ctx, children) do
    check_all_children_completed(activity, ctx, children, [])
  end

  defp check_all_children_completed(activity, ctx, [], result) do
    Activity.Parallel.complete_parallel(activity, ctx, result)
  end

  defp check_all_children_completed(activity, ctx, [{:continue, _} | _children], result) do
    # Still running, waiting for command
    {:ok, :no_event}
  end

  defp check_all_children_completed(activity, ctx, [{:succeed, r} | children], result) do
    check_all_children_completed(activity, ctx, children, [r | result])
  end
end
