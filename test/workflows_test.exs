defmodule WorkflowsTest do
  use ExUnit.Case
  doctest Workflows

  alias Workflows.Command
  alias Workflows.Execution
  alias Workflows.Workflow

  @ctx %{
    "environment" => "development",
  }

  @simple_workflow %{
    "StartAt" => "S1",
    "States" => %{
      "S1" => %{
        "Type" => "Pass",
        "Next" => "S2"
      },
      "S2" => %{
        "Type" => "Succeed"
      }
    }
  }

    @simple_wait_workflow %{
      "StartAt" => "S1",
      "States" => %{
        "S1" => %{
          "Type" => "Wait",
          "SecondsPath" => "$.duration",
          "Next" => "S2"
        },
        "S2" => %{
          "Type" => "Succeed"
        }
      }
    }

    @simple_parallel_workflow %{
      "StartAt" => "S1",
      "States" => %{
        "S1" => %{
          "Type" => "Parallel",
          "Branches" => [%{
            "StartAt" => "A1",
            "States" => %{
              "A1" => %{
                "Type" => "Pass",
                "End" => true
              }
            }
          }, %{
            "StartAt" => "B1",
            "States" => %{
              "B1" => %{
                "Type" => "Succeed"
              }
            }
          }],
          "Next" => "S2"
        },
        "S2" => %{
          "Type" => "Succeed"
        }
      }
    }

  test "simple workflow" do
    {:ok, wf} = Workflow.parse(@simple_workflow)

    {:ok, _exec, _events} = Execution.start(wf, @ctx, %{"foo" => 42})
  end

  test "simple wait workflow" do
    {:ok, wf} = Workflow.parse(@simple_wait_workflow)

    {:ok, exec, _events} = Execution.start(wf, @ctx, %{"foo" => 42})

    fire = Command.fire_timer()
    {:ok, _new_exec, _new_events} = Execution.execute(exec, fire)
  end

  test "simple parallel workflow" do
    {:ok, wf} = Workflow.parse(@simple_parallel_workflow)

    {:ok, exec, _events} = Execution.start(wf, @ctx, %{"foo" => 42})

    start_parallel = Command.start_parallel()
    {:ok, _new_exec, _new_events} = Execution.execute(exec, start_parallel)
  end

end
