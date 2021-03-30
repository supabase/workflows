defmodule WorkflowsTest do
  use ExUnit.Case
  doctest Workflows

  alias Workflows.Command
  alias Workflows.Execution
  alias Workflows.Event
  alias Workflows.Workflow

  @ctx %{
    "environment" => "development"
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
        "Branches" => [
          %{
            "StartAt" => "A1",
            "States" => %{
              "A1" => %{
                "Type" => "Pass",
                "End" => true
              }
            }
          },
          %{
            "StartAt" => "B1",
            "States" => %{
              "B1" => %{
                "Type" => "Succeed"
              }
            }
          }
        ],
        "Next" => "S2"
      },
      "S2" => %{
        "Type" => "Succeed"
      }
    }
  }

  @parallel_workflow_with_wait %{
    "StartAt" => "S1",
    "States" => %{
      "S1" => %{
        "Type" => "Parallel",
        "Branches" => [
          %{
            "StartAt" => "A1",
            "States" => %{
              "A1" => %{
                "Type" => "Wait",
                "Seconds" => 5,
                "End" => true
              }
            }
          },
          %{
            "StartAt" => "B1",
            "States" => %{
              "B1" => %{
                "Type" => "Wait",
                "Seconds" => 10,
                "End" => true,
              }
            }
          }
        ],
        "Next" => "S2"
      },
      "S2" => %{
        "Type" => "Succeed"
      }
    }
  }

  @nested_parallel_workflows %{
    "StartAt" => "S1",
    "States" => %{
      "S1" => %{
        "Type" => "Parallel",
        "Branches" => [
          %{
            "StartAt" => "A1",
            "States" => %{
              "A1" => %{
                "Type" => "Wait",
                "Seconds" => 5,
                "End" => true
              }
            }
          },
          %{
            "StartAt" => "B1",
            "States" => %{
              "B1" => %{
                "Type" => "Parallel",
                "Next" => "B2",
                "Branches" => [
                  %{
                    "StartAt" => "C1",
                    "States" => %{
                      "C1" => %{
                        "Type" => "Wait",
                        "Seconds" => 10,
                        "Next" => "C2"
                      },
                      "C2" => %{
                        "Type" => "Pass",
                        "End" => true
                      }
                    }
                  }
                ]
              },
              "B2" => %{
                "Type" => "Succeed"
              }
            }
          }
        ],
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

    assert exec.state.status == :succeeded
  end

  test "parallel workflow with wait inside" do
    {:ok, wf} = Workflow.parse(@parallel_workflow_with_wait)

    {:ok, exec, events} = Execution.start(wf, @ctx, %{"foo" => 42})

    wait_events =
      events
      |> Enum.filter(fn
        %Event{event: {:wait_started, _}} -> true
        _ -> false
      end)

    wait_0 = Enum.at(wait_events, 0)
    fire = Command.fire_timer() |> Command.with_scope(wait_0.scope)
    {:ok, new_exec, _new_events} = Execution.execute(exec, fire)

    wait_1 = Enum.at(wait_events, 1)
    fire = Command.fire_timer() |> Command.with_scope(wait_1.scope)
    {:ok, new_exec, _new_events} = Execution.execute(new_exec, fire)

    assert new_exec.state.status == :succeeded
  end

  @tag :skip
  test "nested parallel workflow" do
    {:ok, wf} = Workflow.parse(@nested_parallel_workflows)

    {:ok, exec, events} = Execution.start(wf, @ctx, %{"foo" => 42})

    IO.inspect(exec)
    IO.inspect(events)

    assert false
  end
end
