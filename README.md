# Workflows

This package implements a workflow interpreter based on the
[Amazon States Language](https://states-language.net/) specification.

## Installation

This package can be installed by adding `workflows` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:workflows, "~> 0.1.0"}
  ]
end
```

## Usage

<!-- MDOC -->

Workflows implements an Amazon States Language interpreter using event-sourcing, this has the added benefit that
workflows can be suspended and later recovered.

Workflows are created by parsing a map with the workflow definition that conforms to the Amazon States Language
specification.

```elixir
workflow_definition = %{
  "StartAt" => "Start",
  "States" => %{
    "Start" => %{
      "Type" => "Wait",
      "Seconds" => 10,
      "Next" => "End"
    },
    "End" => %{
      "Type" => "Succeed"
    }
  }
}
{:ok, workflow} = Workflows.parse(workflow_definition)
```

You can then start the workflow by calling the `Workflows.start` function and passing a context (a map containing data
that is shared between all states), and the arguments passed to the initial state.
The function returns `{:continue, state, events}` if the workflow execution has to stop to wait for an external command,
or `{:success, result, events}` if the workflow executes to termination.

```elixir
ctx = %{"environment" => "staging"}
args = %{"user" => "alfred@example.org"}
{:continue, execution, events} = Workflows.start(workflow, ctx, args)
IO.inspect events
```

The interpreter does not execute side effects like waiting for a timer or executing a task, instead it returns an event
(for example, `Event.WaitStarted` or `Event.TaskStarted`) and pauses the execution. To resume execution, you should
call the `Workflows.resume` function with a `Command` containing the side effect result (for example, the result of a
`Task`).

```elixir
wait_event = events |> get_wait_event()
finish_wait = Workflows.Command.finish_waiting(wait_event)
{:succeed, result, events} = 
  Workflows.resume(execution, finish_wait)
```

<!-- MDOC -->

## License

This repo is licensed under Apache 2.0.