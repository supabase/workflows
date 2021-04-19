defmodule Workflows.State.WaitTest do
  use ExUnit.Case

  alias Workflows.{Activity, State, Command, Event}

  @ctx %{
    "state" => "wait"
  }

  @activity %{
    "Type" => "Wait",
    "Seconds" => 10,
    "Next" => "NextState"
  }

  test "completes with the FinishWaiting command" do
    {:ok, activity} = Activity.parse("Test", @activity)

    args = %{"values" => [1, 2, 3]}

    state = State.Wait.create(activity, args)

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
    assert {:transition, {:next, "NextState"}, ^args} = State.project(new_state, activity, ended)
  end
end
