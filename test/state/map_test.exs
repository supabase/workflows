defmodule Workflows.State.MapTest do
  use ExUnit.Case

  alias Workflows.{Activity, State, Command}

  @ctx %{
    "state" => "map"
  }

  test "runs all items in parallel by default" do
    activity = %{
      "Type" => "Map",
      "Next" => "NextState",
      "Iterator" => %{
        "StartAt" => "A1",
        "States" => %{
          "A1" => %{
            "Type" => "Task",
            "Resource" => "supabase:send-email",
            "End" => true
          }
        }
      }
    }

    {:ok, activity} = Activity.parse("Test", activity)

    state = State.Map.create(activity, [10, 20])

    {:ok, entered} = State.execute(state, activity, @ctx)

    {:stay, new_state} = State.project(state, activity, entered)
    {:ok, started} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, started)
    {:ok, a1_0_entered} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, a1_0_entered)
    {:ok, a1_0_started} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, a1_0_started)
    {:ok, a1_1_entered} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, a1_1_entered)
    {:ok, a1_1_started} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, a1_1_started)
    {:ok, :no_event} = State.execute(new_state, activity, @ctx)

    # Now 2 tasks are "running" concurrently.

    complete_a1_0 = Command.complete_task(a1_0_started, %{"user_id" => a1_0_started.args})
    {:ok, a1_0_succeed} = State.execute(new_state, activity, @ctx, complete_a1_0)
    complete_a1_1 = Command.complete_task(a1_1_started, %{"user_id" => a1_1_started.args})
    {:ok, a1_1_succeed} = State.execute(new_state, activity, @ctx, complete_a1_1)

    {:stay, new_state} = State.project(new_state, activity, a1_1_succeed)
    {:stay, new_state} = State.project(new_state, activity, a1_0_succeed)
    {:ok, a1_0_exited} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, a1_0_exited)
    {:ok, a1_1_exited} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, a1_1_exited)
    {:ok, succeed} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, succeed)
    {:ok, exited} = State.execute(new_state, activity, @ctx)

    {:transition, {:next, "NextState"}, result} = State.project(new_state, activity, exited)

    assert length(result) == 2
  end

  test "runs a maximum number of items in parallel if MaxConcurrency is set" do
    activity = %{
      "Type" => "Map",
      "Next" => "NextState",
      "MaxConcurrency" => 1,
      "Iterator" => %{
        "StartAt" => "A1",
        "States" => %{
          "A1" => %{
            "Type" => "Task",
            "Resource" => "supabase:send-email",
            "End" => true
          }
        }
      }
    }

    {:ok, activity} = Activity.parse("Test", activity)

    state = State.Map.create(activity, [10, 20])

    {:ok, entered} = State.execute(state, activity, @ctx)

    {:stay, new_state} = State.project(state, activity, entered)
    {:ok, started} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, started)
    {:ok, a1_0_entered} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, a1_0_entered)
    {:ok, a1_0_started} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, a1_0_started)
    {:ok, :no_event} = State.execute(new_state, activity, @ctx)

    # Wait for task A1 0 to finish before starting next item
    complete_a1_0 = Command.complete_task(a1_0_started, %{"user_id" => a1_0_started.args})
    {:ok, a1_0_succeed} = State.execute(new_state, activity, @ctx, complete_a1_0)

    {:stay, new_state} = State.project(new_state, activity, a1_0_succeed)
    {:ok, a1_0_exited} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, a1_0_exited)
    {:ok, a1_1_entered} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, a1_1_entered)
    {:ok, a1_1_started} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, a1_1_started)
    {:ok, :no_event} = State.execute(new_state, activity, @ctx)

    complete_a1_1 = Command.complete_task(a1_1_started, %{"user_id" => a1_1_started.args})
    {:ok, a1_1_succeed} = State.execute(new_state, activity, @ctx, complete_a1_1)

    {:stay, new_state} = State.project(new_state, activity, a1_1_succeed)
    {:ok, a1_1_exited} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, a1_1_exited)
    {:ok, succeed} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, succeed)
    {:ok, exited} = State.execute(new_state, activity, @ctx)

    {:transition, {:next, "NextState"}, result} = State.project(new_state, activity, exited)

    assert length(result) == 2
  end
end
