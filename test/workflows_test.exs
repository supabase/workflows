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
        "Seconds" => 10,
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
                "End" => true
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

    {:succeed, result, events} = Execution.start(wf, @ctx, %{"foo" => 42})
    {:succeed, result_replay} = Workflow.project(wf, events)

    assert result == result_replay
  end

  test "simple wait workflow" do
    {:ok, wf} = Workflow.parse(@simple_wait_workflow)

    {:continue, state, events} = Execution.start(wf, @ctx, %{"foo" => 42})

    wait_started = List.last(events)
    assert %Event.WaitStarted{} = wait_started

    cmd = Command.finish_waiting(wait_started)
    {:succeed, result, new_events} = Execution.resume(wf, state, @ctx, cmd)

    {:succeed, result_replay} = Workflow.project(wf, events ++ new_events)
    assert result == result_replay
  end

  test "simple parallel workflow" do
    {:ok, wf} = Workflow.parse(@simple_parallel_workflow)

    {:succeed, result, _events} = Execution.start(wf, @ctx, %{"foo" => 42})

    assert length(result) == 2
  end

  test "parallel workflow with wait inside" do
    {:ok, wf} = Workflow.parse(@parallel_workflow_with_wait)

    {:continue, state, events} = Execution.start(wf, @ctx, %{"foo" => 42})

    wait_b1 =
      events
      |> Enum.find(fn
        %Event.WaitStarted{activity: "B1"} -> true
        _ -> false
      end)

    wait_a1 =
      events
      |> Enum.find(fn
        %Event.WaitStarted{activity: "A1"} -> true
        _ -> false
      end)

    finish_b1 = Command.finish_waiting(wait_b1)
    {:continue, state, _events} = Execution.resume(wf, state, @ctx, finish_b1)

    finish_a1 = Command.finish_waiting(wait_a1)
    {:succeed, result, _events} = Execution.resume(wf, state, @ctx, finish_a1)

    assert length(result) == 2
  end

  test "nested parallel workflow" do
    {:ok, wf} = Workflow.parse(@nested_parallel_workflows)

    {:continue, state, events} = Execution.start(wf, @ctx, %{"foo" => 42})

    wait_c1 =
      events
      |> Enum.find(fn
        %Event.WaitStarted{activity: "C1"} -> true
        _ -> false
      end)

    wait_a1 =
      events
      |> Enum.find(fn
        %Event.WaitStarted{activity: "A1"} -> true
        _ -> false
      end)

    finish_a1 = Command.finish_waiting(wait_a1)
    {:continue, state, _events} = Execution.resume(wf, state, @ctx, finish_a1)

    finish_c1 = Command.finish_waiting(wait_c1)
    {:succeed, result, _events} = Execution.resume(wf, state, @ctx, finish_c1)

    assert [[_], _] = result
  end
end
