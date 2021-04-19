defmodule Workflows.State.TaskTest do
  use ExUnit.Case

  alias Workflows.{Activity, State, Command, Event, Error}

  @ctx %{
    "state" => "task"
  }

  @state_args %{
    "user" => %{
      "name" => "Max",
      "surname" => "Power"
    }
  }

  @activity %{
    "Type" => "Task",
    "Resource" => "supabase:send-email",
    "Next" => "NextState",
    "Retry" => [
      %{
        "ErrorEquals" => ["ErrorA", "ErrorB"],
        "IntervalSeconds" => 1,
        "BackoffRate" => 2,
        "MaxAttempts" => 2
      },
      %{
        "ErrorEquals" => ["ErrorC"],
        "IntervalSeconds" => 5,
        "MaxAttempts" => 1
      }
    ],
    "Catch" => [
      %{
        "ErrorEquals" => ["ErrorB"],
        "Next" => "Z"
      }
    ]
  }

  test "completes with CompleteTask command" do
    {:ok, activity} = Activity.parse("Test", @activity)

    state = State.Task.create(activity, @state_args)

    {:ok, entered} = State.execute(state, activity, @ctx)
    {:stay, new_state} = State.project(state, activity, entered)
    {:ok, started} = State.execute(new_state, activity, @ctx)
    {:stay, new_state} = State.project(new_state, activity, started)

    assert %Event.TaskStarted{resource: "supabase:send-email"} = started

    {:ok, :no_event} = State.execute(new_state, activity, @ctx)

    finish_waiting = Command.complete_task(started, %{"email_id" => "abcdef"})

    {:ok, finished} = State.execute(new_state, activity, @ctx, finish_waiting)

    assert %Event.TaskSucceeded{} = finished

    {:stay, new_state} = State.project(new_state, activity, finished)
    {:ok, ended} = State.execute(new_state, activity, @ctx)
    {:transition, {:next, "NextState"}, result} = State.project(new_state, activity, ended)

    assert %{"email_id" => "abcdef"} = result
  end

  test "retries task with FailTask command, then catch" do
    {:ok, activity} = Activity.parse("Test", @activity)

    state = State.Task.create(activity, @state_args)

    {:ok, entered} = State.execute(state, activity, @ctx)
    {:stay, new_state} = State.project(state, activity, entered)
    {:ok, started} = State.execute(new_state, activity, @ctx)
    {:stay, new_state} = State.project(new_state, activity, started)

    assert %Event.TaskStarted{resource: "supabase:send-email"} = started

    {:ok, :no_event} = State.execute(new_state, activity, @ctx)

    error_b = Error.create("ErrorB", "Something went wrong")
    fail_task = Command.fail_task(started, error_b)
    {:ok, retried} = State.execute(new_state, activity, @ctx, fail_task)
    assert %Event.TaskRetried{retry_count: 0} = retried
    {:stay, new_state} = State.project(new_state, activity, retried)

    error_c = Error.create("ErrorC", "Something went wrong")
    fail_task = Command.fail_task(started, error_c)
    {:ok, retried} = State.execute(new_state, activity, @ctx, fail_task)
    assert %Event.TaskRetried{retry_count: 0} = retried
    {:stay, new_state} = State.project(new_state, activity, retried)

    fail_task = Command.fail_task(started, error_b)
    {:ok, retried} = State.execute(new_state, activity, @ctx, fail_task)
    assert %Event.TaskRetried{retry_count: 1} = retried
    {:stay, new_state} = State.project(new_state, activity, retried)

    {:ok, failed} = State.execute(new_state, activity, @ctx, fail_task)
    assert %Event.TaskFailed{} = failed
    {:transition, {:next, "Z"}, error} = State.project(new_state, activity, failed)
    assert %{"Name" => "ErrorB", "Cause" => "Something went wrong"} = error
  end

  test "retries task with FailTask command, but doesn't catch" do
    {:ok, activity} = Activity.parse("Test", @activity)

    state = State.Task.create(activity, @state_args)

    {:ok, entered} = State.execute(state, activity, @ctx)
    {:stay, new_state} = State.project(state, activity, entered)
    {:ok, started} = State.execute(new_state, activity, @ctx)
    {:stay, new_state} = State.project(new_state, activity, started)

    assert %Event.TaskStarted{resource: "supabase:send-email"} = started

    {:ok, :no_event} = State.execute(new_state, activity, @ctx)

    error_b = Error.create("ErrorB", "Something went wrong")
    fail_task = Command.fail_task(started, error_b)
    {:ok, retried} = State.execute(new_state, activity, @ctx, fail_task)
    assert %Event.TaskRetried{retry_count: 0} = retried
    {:stay, new_state} = State.project(new_state, activity, retried)

    error_c = Error.create("ErrorC", "Something went wrong")
    fail_task = Command.fail_task(started, error_c)
    {:ok, retried} = State.execute(new_state, activity, @ctx, fail_task)
    assert %Event.TaskRetried{retry_count: 0} = retried
    {:stay, new_state} = State.project(new_state, activity, retried)

    fail_task = Command.fail_task(started, error_c)
    {:ok, failed} = State.execute(new_state, activity, @ctx, fail_task)
    assert %Event.TaskFailed{} = failed
    {:fail, error} = State.project(new_state, activity, failed)

    assert "ErrorC" == error.name
    assert "Something went wrong" == error.cause
  end
end
