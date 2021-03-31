defmodule Workflows.StateTest do
  use ExUnit.Case
  doctest Workflows

  alias Workflows.Activity
  alias Workflows.Command
  alias Workflows.Event
  alias Workflows.State

  @state_args %{
    "foo" => 42
  }

  @ctx %{
    "environment" => "test"
  }

  describe "Choice" do
    @activity %{
      "Type" => "Choice",
      "Default" => "DefaultState",
      "Choices" => [
        %{
          "Next" => "Public",
          "Not" => %{
            "Variable" => "$.type",
            "StringEquals" => "Private"
          }
        },
        %{
          "Next" => "ValueInTwenties",
          "And" => [
            %{
              "Variable" => "$.value",
              "IsPresent" => true
            },
            %{
              "Variable" => "$.value",
              "IsNumeric" => true
            },
            %{
              "Variable" => "$.value",
              "NumericGreaterThanEquals" => 20
            },
            %{
              "Variable" => "$.value",
              "NumericLessThan" => 30
            }
          ]
        }
      ]
    }

    test "completes without external commands" do
      {:ok, activity} = Activity.parse("Test", @activity)

      state = State.Choice.create(activity, %{"type" => "Private", "value" => 25})

      {:ok, started} = State.execute(state, activity, @ctx)
      {:stay, new_state} = State.project(state, activity, started)
      {:ok, ended} = State.execute(new_state, activity, @ctx)

      {:transition, {:next, "ValueInTwenties"}, result} =
        State.project(new_state, activity, ended)
    end

    test "completes without external commands and moves to default" do
      {:ok, activity} = Activity.parse("Test", @activity)

      state = State.Choice.create(activity, %{"type" => "Private", "value" => 35})

      {:ok, started} = State.execute(state, activity, @ctx)
      {:stay, new_state} = State.project(state, activity, started)
      {:ok, ended} = State.execute(new_state, activity, @ctx)
      {:transition, {:next, "DefaultState"}, result} = State.project(new_state, activity, ended)
    end
  end

  describe "Fail" do
    @activity %{
      "Type" => "Fail",
      "Error" => "CustomError",
      "Cause" => "Failing"
    }

    test "completes and fails without external commands" do
      {:ok, activity} = Activity.parse("Test", @activity)

      state = State.Fail.create(activity, @args)

      {:ok, started} = State.execute(state, activity, @ctx)
      {:stay, new_state} = State.project(state, activity, started)
      {:ok, ended} = State.execute(new_state, activity, @ctx)
      {:fail, error} = State.project(new_state, activity, ended)

      assert "CustomError" == error.name
      assert "Failing" == error.cause
    end
  end

  describe "Parallel" do
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

      {:transition, {:next, "NextState"}, result} = State.project(new_state, activity, exited)
    end
  end

  describe "Pass" do
    test "completes without external commands" do
      {:ok, activity} =
        Activity.parse("Test", %{
          "Type" => "Pass",
          "Next" => "NextState"
        })

      state = State.Pass.create(activity, @state_args)

      {:ok, started} = State.execute(state, activity, @ctx)
      {:stay, new_state} = State.project(state, activity, started)
      {:ok, ended} = State.execute(new_state, activity, @ctx)
      {:transition, {:next, "NextState"}, result} = State.project(new_state, activity, ended)
    end
  end

  describe "Succeed" do
    test "completes without external commands" do
      {:ok, activity} =
        Activity.parse("Test", %{
          "Type" => "Succeed"
        })

      state = State.Succeed.create(activity, @state_args)

      {:ok, started} = State.execute(state, activity, @ctx)
      {:stay, new_state} = State.project(state, activity, started)
      {:ok, ended} = State.execute(new_state, activity, @ctx)
      {:succeed, result} = State.project(new_state, activity, ended)
    end
  end

  describe "Wait" do
    @activity %{
      "Type" => "Wait",
      "Seconds" => 10,
      "Next" => "NextState"
    }

    test "completes with the FinishWaiting command" do
      {:ok, activity} = Activity.parse("Test", @activity)

      state = State.Wait.create(activity, @state_args)

      {:ok, entered} = State.execute(state, activity, @ctx)
      {:stay, new_state} = State.project(state, activity, entered)
      {:ok, started} = State.execute(new_state, activity, @ctx)
      {:stay, new_state} = State.project(new_state, activity, started)

      assert %Event.WaitStarted{wait: {:seconds, 10}} = started

      {:ok, :no_event} = State.execute(new_state, activity, @ctx)

      finish_waiting = %Command.FinishWaiting{
        activity: started.activity,
        scope: started.scope
      }

      {:ok, finished} = State.execute(new_state, activity, @ctx, finish_waiting)

      assert %Event.WaitSucceeded{} = finished

      {:stay, new_state} = State.project(new_state, activity, finished)
      {:ok, ended} = State.execute(new_state, activity, @ctx)
      {:transition, {:next, "NextState"}, result} = State.project(new_state, activity, ended)
    end
  end

  describe "Task" do
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
          "IntervalSeconds" => 5
        }
      ],
      "Catch" => [
        %{
          "ErrorEquals" => ["States.ALL"],
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

      finish_waiting = %Command.CompleteTask{
        activity: started.activity,
        scope: started.scope,
        result: %{"email_id" => "abcdef"}
      }

      {:ok, finished} = State.execute(new_state, activity, @ctx, finish_waiting)

      assert %Event.TaskSucceeded{} = finished

      {:stay, new_state} = State.project(new_state, activity, finished)
      {:ok, ended} = State.execute(new_state, activity, @ctx)
      {:transition, {:next, "NextState"}, result} = State.project(new_state, activity, ended)

      assert %{"email_id" => "abcdef"} = result
    end
  end
end
