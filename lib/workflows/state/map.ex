defmodule Workflows.State.Map do
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

  defp do_execute(%State.Map{} = state, %Activity.Map{} = activity, ctx) do
    case state.inner do
      {:before_enter, state_args} ->
        Activity.enter(activity, ctx, state_args)

      {:starting, _state_args, effective_args} ->
        Activity.Map.start_map(activity, ctx, effective_args)

      {:running, _state_args, _effective_args, children} ->
        case execute_child(activity.iterator, children, activity.max_concurrency, 0, 0, ctx) do
          {:ok, :no_event} ->
            check_all_children_completed(activity, ctx, children)

          {:ok, event} ->
            {:ok, event}
        end

      {:map_finished, state_args, result} ->
        Activity.exit(activity, ctx, state_args, result)
    end
  end

  defp do_execute_command(%State.Map{} = state, %Activity.Map{} = activity, ctx, cmd) do
    case state.inner do
      {:running, _state_args, _effective_args, children} ->
        case Command.pop_scope(cmd) do
          {{:item, item_index}, cmd} ->
            child_state = Enum.at(children, item_index)

            case child_state do
              {:continue, child_state} ->
                with {:ok, event} <- Workflow.execute(activity.iterator, child_state, ctx, cmd) do
                  case event do
                    :no_event ->
                      {:ok, :no_event}

                    event ->
                      {
                        :ok,
                        event
                        |> Event.push_scope({:item, item_index})
                      }
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

  defp do_project(%State.Map{} = state, activity, event) do
    case event.scope do
      [] -> do_project_this_scope(state, activity, event)
      _ -> do_project_scoped(state, activity, event)
    end
  end

  defp do_project_this_scope(
         %State.Map{} = state,
         _activity,
         %Event.MapEntered{} = event
       ) do
    case state.inner do
      {:before_enter, state_args} ->
        new_state = %State.Map{state | inner: {:starting, state_args, event.args}}
        {:stay, new_state}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project_this_scope(
         %State.Map{} = state,
         activity,
         %Event.MapStarted{} = event
       ) do
    case state.inner do
      {:starting, state_args, effective_args} ->
        with {:ok, children} = create_children_starting_state(activity.iterator, effective_args) do
          new_state = %State.Map{
            state
            | inner: {:running, state_args, effective_args, children}
          }

          {:stay, new_state}
        end

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project_this_scope(
         %State.Map{} = state,
         _activity,
         %Event.MapSucceeded{} = event
       ) do
    case state.inner do
      {:running, state_args, _, _children} ->
        new_state = %State.Map{state | inner: {:map_finished, state_args, event.result}}
        {:stay, new_state}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project_this_scope(
         %State.Map{} = state,
         _activity,
         %Event.MapExited{} = event
       ) do
    case state.inner do
      {:map_finished, _state_args, _args} ->
        {:transition, event.transition, event.result}

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp do_project_this_scope(_state, _activity, event) do
    {:error, :invalid_event, event}
  end

  defp do_project_scoped(%State.Map{} = state, activity, event) do
    case state.inner do
      {:running, state_args, effective_args, children} ->
        case Event.pop_scope(event) do
          {{:item, item_index}, event} ->
            child_state = Enum.at(children, item_index)

            case child_state do
              {:continue, child_state} ->
                new_child_state = project_child(child_state, activity.iterator, event)
                new_children = List.replace_at(children, item_index, new_child_state)

                new_state = %State.Map{
                  state
                  | inner: {:running, state_args, effective_args, new_children}
                }

                {:stay, new_state}

              _ ->
                # Wrong item index
                {:error, :invalid_event, event}
            end

          {_, _} ->
            {:error, :invalid_event, event}
        end

      _ ->
        {:error, :invalid_event, event}
    end
  end

  defp create_children_starting_state(iterator, args) do
    create_children_starting_state(iterator, args, [])
  end

  defp create_children_starting_state(_iterator, [], children) do
    {:ok, Enum.reverse(children)}
  end

  defp create_children_starting_state(iterator, [args | rest], children) do
    with {:ok, activity} <- Workflow.starting_activity(iterator) do
      state = State.create(activity, args)
      create_children_starting_state(iterator, rest, [{:continue, state} | children])
    end
  end

  # Finished executing all children
  defp execute_child(iterator, [], _max_concurrency, _num_running, _item_index, _ctx),
    do: {:ok, :no_event}

  defp execute_child(
         iterator,
         [{:continue, child} | children],
         max_concurrency,
         num_running,
         item_index,
         ctx
       ) do
    if max_concurrency > 0 and max_concurrency <= num_running do
      {:ok, :no_event}
    else
      with {:ok, activity} <- Workflow.activity(iterator, child.activity),
           {:ok, event} <- State.execute(child, activity, ctx) do
        case event do
          :no_event ->
            execute_child(
              iterator,
              children,
              max_concurrency,
              num_running + 1,
              item_index + 1,
              ctx
            )

          event ->
            {
              :ok,
              event
              |> Event.push_scope({:item, item_index})
            }
        end
      end
    end
  end

  defp execute_child(
         iterator,
         [{:succeed, _result} | children],
         max_concurrency,
         num_running,
         item_index,
         ctx
       ) do
    # Succeeded items don't count towards the number of concurrently running tasks
    execute_child(iterator, children, max_concurrency, num_running, item_index + 1, ctx)
  end

  defp project_child(child_state, iterator, event) do
    Workflow.project(iterator, child_state, event)
  end

  defp check_all_children_completed(activity, ctx, children) do
    check_all_children_completed(activity, ctx, children, [])
  end

  defp check_all_children_completed(activity, ctx, [], result) do
    Activity.Map.complete_map(activity, ctx, result)
  end

  defp check_all_children_completed(activity, ctx, [{:continue, _} | _children], result) do
    # Still running, waiting for command
    {:ok, :no_event}
  end

  defp check_all_children_completed(activity, ctx, [{:succeed, r} | children], result) do
    check_all_children_completed(activity, ctx, children, [r | result])
  end
end
