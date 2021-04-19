defmodule Workflows.State.PassTest do
  use ExUnit.Case

  alias Workflows.{Activity, State}

  @ctx %{
    "state" => "pass"
  }

  @activity %{
    "Type" => "Pass",
    "Next" => "NextState"
  }

  test "completes without external commands" do
    {:ok, activity} = Activity.parse("Test", @activity)

    args = %{"arg1" => 123}

    state = State.Pass.create(activity, args)

    {:ok, started} = State.execute(state, activity, @ctx)
    {:stay, new_state} = State.project(state, activity, started)
    {:ok, ended} = State.execute(new_state, activity, @ctx)
    assert {:transition, {:next, "NextState"}, ^args} = State.project(new_state, activity, ended)
  end
end
