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

  @parallel_inside_map_workflow %{
    "StartAt" => "SendEmailsToUsers",
    "States" => %{
      "SendEmailsToUsers" => %{
        "Type" => "Map",
        "End" => true,
        "InputPath" => "$.changes",
        "Iterator" => %{
          "StartAt" => "CheckInsert",
          "States" => %{
            "CheckInsert" => %{
              "Type" => "Choice",
              "Default" => "Complete",
              "Choices" => [
                %{
                  "Variable" => "$.type",
                  "StringEquals" => "INSERT",
                  "Next" => "WaitOneDay"
                }
              ]
            },
            "WaitOneDay" => %{
              "Type" => "Wait",
              "Next" => "SendEmail",
              "Seconds" => 86400
            },
            "SendEmail" => %{
              "Type" => "Task",
              "Next" => "Complete",
              "Resource" => "send-templated-email",
              "Parameters" => %{
                "api_key" => "my-api-key",
                "template_id" => "welcome-email",
                "payload" => %{
                  "name.$" => "$.record.name",
                  "email.$" => "$.record.email"
                }
              }
            },
            "Complete" => %{
              "Type" => "Succeed"
            }
          }
        }
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

  test "parallel inside map workflow" do
    db_changes = %{
      "changes" => [
        %{
          "columns" => [
            %{
              "flags" => ["key"],
              "name" => "id",
              "type" => "int8",
              "type_modifier" => 4_294_967_295
            },
            %{
              "flags" => [],
              "name" => "name",
              "type" => "text",
              "type_modifier" => 4_294_967_295
            },
            %{
              "flags" => [],
              "name" => "email",
              "type" => "text",
              "type_modifier" => 4_294_967_295
            }
          ],
          "commit_timestamp" => "2021-03-17T14:00:26Z",
          "record" => %{
            "id" => "101492",
            "name" => "Alfred",
            "email" => "alfred@example.org"
          },
          "schema" => "public",
          "table" => "users",
          "type" => "INSERT"
        }
      ],
      "commit_timestamp" => "2021-03-17T14:00:26Z"
    }

    {:ok, wf} = Workflows.parse(@parallel_inside_map_workflow)

    {:continue, state, events} = Workflows.start(wf, @ctx, db_changes)

    # Look for event to wait for one day
    wait_one_day =
      events
      |> Enum.find(fn
        %Event.WaitStarted{activity: "WaitOneDay"} -> true
        _ -> false
      end)

    # Don't wait for one day :)
    finish_waiting_command = Command.finish_waiting(wait_one_day)
    {:continue, state, events} = Workflows.resume(wf, state, @ctx, finish_waiting_command)

    task_started =
      events
      |> Enum.find(fn
        %Event.TaskStarted{activity: "SendEmail"} -> true
        _ -> false
      end)

    # Check that the arguments to the task are correct
    assert %{"email" => "alfred@example.org", "name" => "Alfred"} = task_started.args["payload"]

    # Let's say the API responded with a message-id for the sent email
    complete_task_command = Command.complete_task(task_started, %{"message_id" => 123})
    {:succeed, result, _events} = Workflows.resume(wf, state, @ctx, complete_task_command)
    # Result is inside a list because we are mapping over all inserted users
    assert [%{"message_id" => 123}] = result
  end
end
