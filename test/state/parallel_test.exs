defmodule Workflows.State.ParallelTest do
  use ExUnit.Case

  alias Workflows.{Activity, State, Command}

  @ctx %{
    "state" => "parallel"
  }

  @state_args %{
    "channel_id" => "channel-123"
  }

  @activity %{
    "Type" => "Parallel",
    "Next" => "NextState",
    "Branches" => [
      %{
        "StartAt" => "B1",
        "States" => %{
          "B1" => %{
            "Type" => "Task",
            "Resource" => "supabase:slack-notification",
            "Next" => "B2"
          },
          "B2" => %{
            "Type" => "Pass",
            "End" => true
          }
        }
      },
      %{
        "StartAt" => "A1",
        "States" => %{
          "A1" => %{
            "Type" => "Pass",
            "Next" => "A2"
          },
          "A2" => %{
            "Type" => "Succeed"
          }
        }
      }
    ]
  }

  test "completes when children complete" do
    {:ok, activity} = Activity.parse("Test", @activity)

    state = State.Parallel.create(activity, @state_args)

    {:ok, entered} = State.execute(state, activity, @ctx)
    {:stay, new_state} = State.project(state, activity, entered)
    {:ok, started} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, started)
    {:ok, b1_entered} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, b1_entered)
    {:ok, b1_started} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, b1_started)
    {:ok, a1_entered} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, a1_entered)
    {:ok, a1_exited} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, a1_exited)
    {:ok, a2_entered} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, a2_entered)
    {:ok, a2_exited} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, a2_exited)
    {:ok, :no_event} = State.execute(new_state, activity, @ctx)

    # Now we continue Task b1

    finish_waiting_b1 = %Command.CompleteTask{
      activity: b1_started.activity,
      scope: b1_started.scope,
      result: %{"email_id" => "abcdef"}
    }

    {:ok, b1_succeeded} = State.execute(new_state, activity, @ctx, finish_waiting_b1)

    {:stay, new_state} = State.project(new_state, activity, b1_succeeded)
    {:ok, b1_exited} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, b1_exited)
    {:ok, b2_entered} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, b2_entered)
    {:ok, b2_exited} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, b2_exited)
    {:ok, succeeded} = State.execute(new_state, activity, @ctx)

    {:stay, new_state} = State.project(new_state, activity, succeeded)
    {:ok, exited} = State.execute(new_state, activity, @ctx)

    {:transition, {:next, "NextState"}, _result} = State.project(new_state, activity, exited)
  end
end
