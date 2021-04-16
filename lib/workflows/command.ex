defmodule Workflows.Command do
  @moduledoc false

  alias Workflows.{Activity, Command, Event, Error, Execution}

  @type t :: struct()

  @spec pop_scope(t()) :: {Execution.scope() | nil, t()}
  def pop_scope(command) do
    Map.get_and_update(command, :scope, fn
      [] -> {nil, []}
      [current | scope] -> {current, scope}
    end)
  end

  @spec finish_waiting(Event.WaitStarted.t()) :: Command.FinishWaiting.t()
  def finish_waiting(%Event.WaitStarted{} = event) do
    %Command.FinishWaiting{
      activity: event.activity,
      scope: event.scope
    }
  end

  @spec complete_task(Event.TaskStarted.t(), Activity.args()) :: Command.CompleteTask.t()
  def complete_task(%Event.TaskStarted{} = event, result) do
    %Command.CompleteTask{
      activity: event.activity,
      scope: event.scope,
      result: result
    }
  end

  @spec fail_task(Event.TaskStarted.t(), Error.t()) :: Command.FailTask.t()
  def fail_task(%Event.TaskStarted{} = event, error) do
    %Command.FailTask{
      activity: event.activity,
      scope: event.scope,
      error: error
    }
  end
end
