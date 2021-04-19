defmodule Workflows.State.FailTest do
  use ExUnit.Case

  alias Workflows.{Activity, State}

  @ctx %{
    "state" => "fail"
  }

  @activity %{
    "Type" => "Fail",
    "Error" => "CustomError",
    "Cause" => "Failing"
  }

  test "completes and fails without external commands" do
    {:ok, activity} = Activity.parse("Test", @activity)

    state = State.Fail.create(activity, %{})

    {:ok, started} = State.execute(state, activity, @ctx)
    {:stay, new_state} = State.project(state, activity, started)
    {:ok, ended} = State.execute(new_state, activity, @ctx)
    {:fail, error} = State.project(new_state, activity, ended)

    assert "CustomError" == error.name
    assert "Failing" == error.cause
  end
end
