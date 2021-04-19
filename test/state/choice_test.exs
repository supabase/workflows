defmodule Workflows.State.ChoiceTest do
  use ExUnit.Case

  alias Workflows.{Activity, State}

  @ctx %{
    "state" => "choice"
  }

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

    {:transition, {:next, "ValueInTwenties"}, _result} = State.project(new_state, activity, ended)
  end

  test "completes without external commands and moves to default" do
    {:ok, activity} = Activity.parse("Test", @activity)

    state = State.Choice.create(activity, %{"type" => "Private", "value" => 35})

    {:ok, started} = State.execute(state, activity, @ctx)
    {:stay, new_state} = State.project(state, activity, started)
    {:ok, ended} = State.execute(new_state, activity, @ctx)
    {:transition, {:next, "DefaultState"}, _result} = State.project(new_state, activity, ended)
  end
end
