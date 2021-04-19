defmodule Workflows.State.SucceedTest do
  use ExUnit.Case

  alias Workflows.{Activity, State}

  @ctx %{
    "state" => "succeed"
  }

  @activity %{
    "Type" => "Succeed"
  }

  test "completes without external commands" do
    {:ok, activity} = Activity.parse("Test", @activity)

    args = %{"running" => "yes"}

    state = State.Succeed.create(activity, args)

    {:ok, started} = State.execute(state, activity, @ctx)
    {:stay, new_state} = State.project(state, activity, started)
    {:ok, ended} = State.execute(new_state, activity, @ctx)
    assert {:succeed, ^args} = State.project(new_state, activity, ended)
  end
end
